Shader "Practice/ProceduralCheckerboard"
{
    Properties
    {
        // 开放缩放比例，让美术可以在材质面板自由控制格子密度
        _Scale ("Grid Scale", Range(1, 50)) = 10.0
        
        // 我们不一定要黑白，暴露两个颜色出去让美术自己配
        _ColorEven ("Even Color (e.g. Black)", Color) = (0, 0, 0, 1)
        _ColorOdd ("Odd Color (e.g. White)", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0; // 获取模型最原始的 UV
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float _Scale;
            fixed4 _ColorEven;
            fixed4 _ColorOdd;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv; // 直接把 UV 传给片段着色器
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 放大 UV 空间
                float2 scaledUV = i.uv * _Scale;

                // 2. 将连续的浮点数切分成离散的整数格子
                // 例如 2.3 变成 2.0；4.8 变成 4.0
                float2 grid = floor(scaledUV);

                // 3. 将 X 和 Y 的整数相加
                float sum = grid.x + grid.y;

                // 4. 【核心魔法：高效的奇偶判断】
                // 如果 sum 是偶数 (例如 4)：4 * 0.5 = 2.0。 frac(2.0) = 0.0。 0.0 * 2 = 0.0。
                // 如果 sum 是奇数 (例如 5)：5 * 0.5 = 2.5。 frac(2.5) = 0.5。 0.5 * 2 = 1.0。
                // 这样我们完美地把偶数变成了 0.0，奇数变成了 1.0，全程没有任何 if-else 分支！
                float checker = frac(sum * 0.5) * 2.0;

                // 5. 颜色混合输出
                // lerp(A, B, 0) = A; lerp(A, B, 1) = B;
                fixed4 finalColor = lerp(_ColorEven, _ColorOdd, checker);

                return finalColor;
            }
            ENDCG
        }
    }
}