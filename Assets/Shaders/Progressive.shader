Shader "Byte/Progressive" {
    Properties{
        // Propiedades del shader
    }
    SubShader{
        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //Definir variables
            sampler2D _MainTexOld;
            sampler2D _MainTex;
            int Frame;

            // Definir las estructuras de entrada y salida del shader
            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct v2f {
                float2 uv : TEXCOORD0;
                float4 v2f : SV_POSITION;
            };


            // Función para transformar los vértices del objeto
            v2f vert(appdata v) {
                v2f o;
                o.v2f = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Función para calcular el color de cada píxel en función de la posición en la pantalla
            float4 frag(v2f i) : SV_Target{
                float4 oldRender = tex2D(_MainTexOld, i.uv);
                float4 newRender = tex2D(_MainTex, i.uv);

                float weigth = 1.0 / (Frame + 1);
                float4 accumulatedAverage = oldRender * (1.0 - weigth) + newRender * (float)weigth;
                //float4 accumulatedAverage = lerp(oldRender, newRender, weigth);
                return accumulatedAverage;
            }
            ENDHLSL
        }
    }
}
