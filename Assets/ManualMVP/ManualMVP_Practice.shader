Shader "Unlit/ManualMVP_Practice"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white"{}
        _RotationAngle("Rotation Angle (Y-Axis)", Range(0, 360)) = 0
        _HeartbeatSpeed("Heartbeat Speed", Float) = 5.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _RotationAngle;
            float _HeartbeatSpeed;

            v2f vert (appdata v)
            {
                v2f o;

                // 1. 准备旋转数据
                // Unity 的三角函数 sin/cos 接受的是“弧度”，而面板输入的是“度”
                // 使用 radians() 函数转换
                float rad = radians(_RotationAngle);
                float c = cos(rad);
                float s = sin(rad);

                // 2. 手动构建旋转矩阵 (绕 Y 轴)
                // 对应 GAMES101 L4 的公式
                // 注意：HLSL 中构建矩阵是按行填充的，但数据结构是 float4x4
                float4x4 rotationMatrix = float4x4(
                     c, 0,  s, 0,
                     0, 1,  0, 0,
                    -s, 0,  c, 0,
                     0, 0,  0, 1
                );

                // 3. 进阶：手动构建缩放矩阵 (心跳效果)
                // 利用 sin(_Time.y) 产生 -1 到 1 的波动
                // 映射到 0.8 到 1.2 的缩放范围，防止缩放到 0 或负数
                float scaleValue = 1.0 + sin(_Time.y * _HeartbeatSpeed) * 0.2;

                float4x4 scaleMatrix = float4x4(
                    scaleValue, 0, 0, 0,
                    0, scaleValue, 0, 0,
                    0, 0, scaleValue, 0,
                    0, 0, 0, 1
                );

                // 4. 组合模型变换 (Model Matrix)
                // 矩阵乘法顺序很重要！
                // 先缩放，再旋转，通常写为 R * S * v
                // 在 Shader 中 mul(Matrix, Vector) 
                
                // 这种做法相当于在手动写 MVP 中的 "M" (Model) 部分
                float4x4 modelMatrix = mul(rotationMatrix, scaleMatrix);

                // 5. 应用变换到顶点
                // 将原始顶点 v.vertex (模型空间) 变换一下
                float4 modifiedPos = mul(modelMatrix, v.vertex);

                // 6. 最后进行 VP 变换 (View * Projection)
                // UnityObjectToClipPos 包含了 Model * View * Projection
                // 但因为我们已经手动把 Model 的效果应用在 modifiedPos 上了
                // 这里的 modifiedPos 实际上还是被当做模型空间的坐标输入
                // 注意：为了单纯演示，这里我们用 UnityObjectToClipPos 把 modifiedPos 当作基于原点的新模型坐标处理
                
                o.vertex = UnityObjectToClipPos(modifiedPos);

                // 处理 UV
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
