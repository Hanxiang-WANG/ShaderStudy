Shader "Unlit/BlinnPhong_Practice"
{
    Properties
    {
        // 我们定义漫反射颜色 (kd)、高光颜色 (ks) 和高光指数 (p)
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss (Shininess)", Range(1.0, 256.0)) = 20.0
    }
    SubShader
    {
        // 重点：加入 "LightMode"="ForwardBase"
        // 这行代码是在告诉 Unity："请把场景里那盏主平行光的数据传给这个 Shader！"
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            // 引入 Lighting.cginc 才能使用 _LightColor0 获取场景光颜色
            #include "Lighting.cginc" 

            struct appdata
            {
                float4 vertex : POSITION;
                // 【新朋友出现】NORMAL 语义：从模型数据中读取顶点的法线！
                float3 normal : NORMAL; 
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // 裁剪空间坐标 (必须)
                // 为了在 frag 里算光照，我们需要把世界空间的法线和坐标传过去
                float3 worldNormal : TEXCOORD0; 
                float3 worldPos : TEXCOORD1;    
            };

            // 声明面板属性
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                // 1. 空间变换 (MVP)
                o.pos = UnityObjectToClipPos(v.vertex);

                // 2. 将法线从模型空间转换到世界空间
                // 等价于 GAMES101 里的: N_world = mul(inv(trans(ModelMatrix)), N_object)
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 3. 将顶点坐标从模型空间转换到世界空间 (用来算视线方向)
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 【准备工作】：获取并归一化三个核心向量 (n, l, v)
                
                // 1. 法线方向 (n) -> 经过光栅化插值后，长度可能不为 1，必须重新 normalize！
                float3 n = normalize(i.worldNormal);
                
                // 2. 光照方向 (l) -> Unity 内置变量 _WorldSpaceLightPos0 提供
                float3 l = normalize(_WorldSpaceLightPos0.xyz);
                
                // 3. 视线方向 (v) -> 摄像机位置减去像素的世界位置
                float3 v = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);


                // 【开始计算 Blinn-Phong 的三部分】

                // A. 环境光 (Ambient) -> 直接取 Unity 环境光设置的值
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.rgb;

                // B. 漫反射 (Diffuse) -> kd * I * max(0, n·l)
                // saturate() 是 Shader 里的常用函数，作用是把数值截断在 0 到 1 之间，等价于 max(0, x)
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(n, l));

                // C. 高光 (Specular) -> ks * I * max(0, n·h)^p
                // 1. 求半程向量 h
                float3 h = normalize(v + l);
                // 2. 求 n·h 并做指数运算 pow()
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(n, h)), _Gloss);

                // 【最终结果】相加！
                fixed3 finalColor = ambient + diffuse + specular;

                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}