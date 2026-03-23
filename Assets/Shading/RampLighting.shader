Shader "Practice/RampLighting_BuiltIn"
{
    Properties
    {
        _MainTex ("Base Color (RGB)", 2D) = "white" {}
        // 【新增】这就是我们的渐变纹理 (Ramp Texture)
        _RampTex ("Ramp Texture (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // 声明渐变纹理
            sampler2D _RampTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 准备法线和光照方向
                float3 n = normalize(i.worldNormal);
                float3 l = normalize(_WorldSpaceLightPos0.xyz);

                // 2. 算半兰伯特值 (Half-Lambert)
                // dot(n, l) 范围是 [-1, 1]
                // 乘以 0.5 加上 0.5 之后，范围完美变成了 [0, 1]
                float halfLambert = dot(n, l) * 0.5 + 0.5;

                // 3. 【核心魔法】查字典！
                // 我们把算出来的 halfLambert 当成 U 坐标 (横坐标)
                // V 坐标 (纵坐标) 给定 0.5 即可，因为 Ramp 图通常是一条 1D 的横向渐变
                fixed3 rampLighting = tex2D(_RampTex, float2(halfLambert, 0.5)).rgb;

                // 4. 采样物体本来的颜色
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;

                // 5. 混合输出：固有色 * 渐变光照 * 光源颜色
                fixed3 finalColor = albedo * rampLighting * _LightColor0.rgb;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}