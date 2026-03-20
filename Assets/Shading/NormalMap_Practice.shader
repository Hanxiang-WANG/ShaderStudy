Shader "Unlit/NormalMap_Practice"
{
    Properties
    {
        // 主纹理（颜色贴图）
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 法线贴图 (注意: 在 Unity 导入设置里要把纹理类型改为 'Normal map')
        _NormalMap ("Normal Map", 2D) = "bump" {}
        // 控制法线强度的滑条
        _BumpScale ("Normal Strength", Range(0, 2)) = 1.0
        // 用于算高光的平滑度
        _Gloss ("Gloss (Shininess)", Range(1.0, 256.0) ) = 20.0
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
            #include "Lighting.cginc" // 为了使用 _LightColor0 获取场景光颜色

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                // 【新朋友】NORMAL 语义：从模型数据中读取顶点的几何法线！
                float3 normal : NORMAL; 
                // 【新朋友】TANGENT 语义：从模型数据中读取顶点的切线，用来构建 TBN 矩阵
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                // 为了在 frag 里算光照，我们需要把世界空间的坐标、光方向和视线传过去
                float3 worldPos : TEXCOORD1;
                // 我们在顶点着色器构建好 TBN 矩阵，用来把法线从切线空间转到世界空间
                float3x3 tbn : COLOR; // COLOR 语义是通用的，这里借用来存矩阵
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _BumpScale;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                // 1. 标准 MVP 变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 2. 处理 UV
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 3. 将顶点坐标转到世界空间 (用来算视线方向)
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos = worldPos;

                // 4. 【核心魔法】在顶点着色器构建 TBN 矩阵
                // 将法线和切线转到世界空间
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 计算副切线 (Bitangent) = Normal x Tangent
                // v.tangent.w 用来确定副切线的方向
                float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;
                
                // 构建 TBN 矩阵：将切线空间 (Tangent Space) 的法线转到世界空间 (World Space)
                // 矩阵的列向量分别是 T、B、N
                o.tbn = float3x3(worldTangent, worldBitangent, worldNormal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 【准备工作】：获取核心向量

                // 1. 从法线贴图采样法线，并解包 (Unpack)
                // tex2D 采样出的是 [0, 1] 的颜色
                // UnpackNormal 函数会把它转换回 [-1, 1] 的法线方向
                // 此时算出来的 n 是处在切线空间下的假法线
                float3 tangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
                
                // 2. 将法线从切线空间转到世界空间
                // mul(向量, 矩阵) 是 HLSL 里的标准列向量乘法 (矩阵在右，向量在左)
                // 这行代码把 tangentNormal 翻译成了能在世界空间算光照的假法线
                float3 n = normalize(mul(tangentNormal, i.tbn));
                
                // 3. 光照方向 (l) -> Unity 内置变量 _WorldSpaceLightPos0 提供
                float3 l = normalize(_WorldSpaceLightPos0.xyz);
                
                // 4. 视线方向 (v) -> 摄像机位置减去像素的世界位置
                float3 v = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);


                // 【开始计算 Blinn-Phong 光照】

                // A. 环境光 (Ambient) -> 直接取 Unity 环境光设置的值
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // B. 漫反射 (Diffuse) -> I * max(0, n·l)
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(n, l));

                // C. 高光 (Specular) -> I * max(0, n·h)^p
                // 1. 求半程向量 h
                float3 h = normalize(v + l);
                // 2. 求 n·h 并做指数运算 pow()
                fixed3 specular = _LightColor0.rgb * pow(saturate(dot(n, h)), _Gloss);


                // 【最终结果】相加！
                fixed3 finalColor = ambient + diffuse + specular;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}