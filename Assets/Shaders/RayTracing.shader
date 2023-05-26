Shader "Byte/RayTracing" {
    Properties{
        // Propiedades del shader
    }
    SubShader{
        Tags {"InterpolateOptions" = "Linear"}
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Incluir UnityCG.cginc para acceder a las funciones de shader de Unity
            #include "UnityCG.cginc"
            
            //Definir variables
            float3 ViewParams;
            float4x4 CamLocalToWorldMatrix;

            // Definir las estructuras de entrada y salida del shader
            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            struct Ray {
                float3 origin;
                float3 dir;
            };
            struct RayTracingMaterial {
                float4 color;
                float4 emissionColor;
                float emissionStrength;
            };
            struct HitInfo {
                bool didHit;
                float dst;
                float3 hitPoint;
                float3 normal;
                RayTracingMaterial material;
            };
            struct Sphere {
                float3 position;
                float radius;
                RayTracingMaterial material;
            };

            StructuredBuffer<Sphere> Spheres;
            int NumSpheres;

            // Función para calcular la intersección de un rayo con una esfera
            HitInfo RaySphere(Ray ray, float3 sphereCentre, float sphereRadius)
            {
                HitInfo hitInfo = (HitInfo)0;
                float3 offsetRayOrigin = ray.origin - sphereCentre;
                // From the equation: sqrLength(rayOrigin + rayDir * dst) = radius^2 
                // Solving for dst results in a quadratic equation with coefficients: 
                float a = dot(ray.dir, ray.dir); // a = 1 (assuming unit vector)
                float b = 2 * dot(offsetRayOrigin, ray.dir);
                float c = dot(offsetRayOrigin, offsetRayOrigin) - sphereRadius * sphereRadius;

                // Quadratic discriminant
                float discriminant = b * b - 4 * a * c;

                // No solution when d < 0 (ray misses sphere)
                if (discriminant >= 0) {
                    // Distance to nearest intersection point (from quadratic formula) 
                    float dst = (-b - sqrt(discriminant)) / (2 * a);
                    // Ignore intersections that occur behind the ray 
                    if (dst >= 0) {
                        hitInfo.didHit = true;
                        hitInfo.dst = dst;
                        hitInfo.hitPoint = ray.origin + ray.dir * dst;
                        hitInfo.normal = normalize(hitInfo.hitPoint - sphereCentre);
                    }
                }
                return hitInfo;
            }

            HitInfo CalculateRayCollision(Ray ray)
            {
                HitInfo closestHit = (HitInfo)0;
                closestHit.dst = 1.#INF;

                for (int i = 0; i < NumSpheres; i++) {
                    Sphere sphere = Spheres[i];
                    HitInfo hitInfo = RaySphere(ray, sphere.position, sphere.radius);

                    if (hitInfo.didHit && hitInfo.dst < closestHit.dst) {
                        closestHit = hitInfo;
                        closestHit.material = sphere.material;
                    }
                }
                return closestHit;
            }

            float RandomValue(inout uint state) {
                state = state * 747796405 + 2891336453;
                uint result = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
                result = (result >> 22) ^ result;
                return result / 4294967295.0;
            }

            float RandomValueNormalDistribution(inout uint state) {
                float theta = 2 * 3.1415 * RandomValue(state);
                float rho = sqrt(-2 * log(RandomValue(state)));
                return rho * cos(theta);
			}

            float3 RandomDirection(inout uint state)
            {
                float x = RandomValueNormalDistribution(state);
                float y = RandomValueNormalDistribution(state);
                float z = RandomValueNormalDistribution(state);
                return normalize(float3(x, y, z));
            }

            float3 RandomHemisphereDirection(float3 normal, inout uint state)
            {
				float3 dir = RandomDirection(state);
                return dir * sign(dot(normal, dir));
			}
            float4 SkyColorHorizon;
            float4 SkyColorZenith;
            float3 SunLightDirection;
            float SunIntensity;
            float SunFocus;
            float4 GroundColor;

            float3 GetEnvironmentLight(Ray ray)
            {
                float skyGradientT = pow(smoothstep(0, 0.4, ray.dir.y), 0.35);
                float3 skyGradient = lerp(SkyColorHorizon.xyz, SkyColorZenith.xyz, skyGradientT);
                float sun = pow(max(0, dot(ray.dir, -SunLightDirection)), SunFocus) * SunIntensity;

                float groundToSkyT = smoothstep(-0.01, 0, ray.dir.y);
                float sunMask = groundToSkyT >= 1;
				return lerp(GroundColor.xyz, skyGradient, groundToSkyT) + sun * sunMask;
			}

            int MaxBounceCount;

            float3 Trace(Ray ray, inout uint rngState)
            {
                float3 incomingLight = 0;
                float3 rayColor = 1;

                for (int i = 0; i <= MaxBounceCount; i++) 
                {
                    HitInfo hitInfo = CalculateRayCollision(ray);
                    if (hitInfo.didHit) 
                    {
                        ray.origin = hitInfo.hitPoint;
                        ray.dir = RandomHemisphereDirection(hitInfo.normal, rngState);

                        RayTracingMaterial material = hitInfo.material;
                        float3 emittedLight = material.emissionColor.xyz * material.emissionStrength;
                        float lightStrength = dot(hitInfo.normal, ray.dir);
                        incomingLight += emittedLight * rayColor;
                        rayColor *= material.color.xyz * lightStrength;
                    }
                    else
                    {
                        incomingLight += GetEnvironmentLight(ray) * rayColor;
                        break;
                    }
                }
                return incomingLight;
            }

            int NumRaysPerPixel;
            int Frame;

            float4 CalculateColor(v2f i, inout uint rngState) {
                float3 viewPointLocal = float3(i.uv - 0.5, 1) * ViewParams;
                float3 viewPoint = mul(CamLocalToWorldMatrix, float4(viewPointLocal, 1)).xyz;

                Ray ray;
                ray.origin = _WorldSpaceCameraPos;
                ray.dir = normalize(viewPoint - ray.origin);

                float3 totalIncomingLight = 0;

                for (int i = 0; i < NumRaysPerPixel; i++) {
                    totalIncomingLight += Trace(ray, rngState);
                }

                float3 pixelCol = totalIncomingLight / NumRaysPerPixel;
                return float4(pixelCol, 1);
            }

            // Función para transformar los vértices del objeto
            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Función para calcular el color de cada píxel en función de la posición en la pantalla
            float4 frag(v2f i) : SV_Target{
                // Calcular el color de cada píxel
                uint2 numPixels = _ScreenParams.xy;
                uint2 pixelCoord = i.uv * numPixels;
                uint pixelIndex = pixelCoord.y * numPixels.x + pixelCoord.x;
                uint rngState = pixelIndex + Frame * 719393;
				return CalculateColor(i, rngState);
            }
            ENDHLSL
        }
    }
}
