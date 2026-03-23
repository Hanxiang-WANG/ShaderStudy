Shader "Practice/BurningDissolve"
{
    Properties
    {
        _MainTex ("Base Color (RGB)", 2D) = "white" {}
        // 【核心遮罩】必须是一张黑白噪波图，控制溶解的路径
        _DissolveMask ("Dissolve Mask (Noise)", 2D) = "gray" {}
        
        // 【控制阀门】0.0 代表完全不溶解，1.0 代表完全溶解消失
        _DissolveThreshold ("Dissolve Progress", Range(0.0, 1.1)) = 0.0
        
        // 【高级细节 1】燃烧边缘的颜色和宽度
        [HDR] _BurnColor ("Burn Glow Color", Color) = (1, 0.3, 0, 1) // 高度饱和的橙色，记得开启HDR
        _BurnWidth ("Burn Glow Width", Range(0.0, 0.2)) = 0.05
        
        // 【高级细节 2】燃烧前的表面变黑（炭化）
        _CharWidth ("Charred Surface Width", Range(0.0, 0.2)) = 0.1
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _DissolveMask; // 遮罩
            float _DissolveThreshold; // 阈值
            fixed4 _BurnColor;
            float _BurnWidth;
            float _CharWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 采样主纹理和遮罩纹理
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                // 采样噪波遮罩的 R 通道作为溶解值
                float maskValue = tex2D(_DissolveMask, i.uv).r;

                // 2. 【溶解核心】剔除计算
                // 如果 (maskValue - 阈值) < 0，这个像素就被彻底扔掉，不画了。
                // 这行代码就是你在上一节学到的 discard 的高效替代。
                clip(maskValue - _DissolveThreshold);

                // 3. 【高级细节】计算表面炭化（变黑）
                // 我们在主阈值之上，再设定一个炭化范围。
                // 那些刚好比溶解阈值大一点点的像素，我们要把它压暗成黑色。
                float isCharred = step(maskValue, _DissolveThreshold + _BurnWidth + _CharWidth);
                if(isCharred > 0.5)
                {
                    albedo *= 0.1; // 炭化变黑
                }

                // 4. 【核心魔法】计算燃烧发光边缘
                // 我们划出一个极窄的“燃烧带”：介于阈值和 (阈值 + 燃烧宽度) 之间。
                // 这里的 step 函数会返回 1 (在燃烧带内) 或 0 (在燃烧带外)
                float isBurning = step(maskValue, _DissolveThreshold + _BurnWidth);
                
                // 将 albedo 和发光颜色进行混合。只有 isBurning 为 1 的地方才会透出橙色。
                fixed3 finalColor = lerp(albedo, _BurnColor.rgb, isBurning);

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}