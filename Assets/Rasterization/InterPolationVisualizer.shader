Shader "Unlit/InterpolationVisualizer"
{
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
                // 这次我们不需要 UV 了，所以可以删掉 TEXCOORD0
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                
                // 【重点1】我们新增一个变量，专门用来在 vert 和 frag 之间传递颜色数据
                // 语义使用 COLOR (告诉显卡这是一组颜色/插值数据)
                float4 myColor : COLOR; 
            };

            v2f vert (appdata v)
            {
                v2f o;
                
                // 1. 标准 MVP 变换，将 3D 模型点投影到 2D 屏幕上
                o.vertex = UnityObjectToClipPos(v.vertex);

                // 2. 【核心魔法】在顶点着色器中，根据顶点的“局部坐标(x,y,z)”来决定它的颜色
                // 比如 Unity 的默认 Cube，它的顶点坐标范围大约是 -0.5 到 +0.5
                // 颜色范围必须是 0.0 到 1.0，所以我们给坐标加上 0.5 进行映射：
                o.myColor.r = v.vertex.x + 0.5; // X坐标决定红色 (Red)
                o.myColor.g = v.vertex.y + 0.5; // Y坐标决定绿色 (Green)
                o.myColor.b = v.vertex.z + 0.5; // Z坐标决定蓝色 (Blue)
                o.myColor.a = 1.0;              // Alpha 设为完全不透明

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 3. 【见证奇迹】不要查贴图了！
                // 直接把光栅化阶段插值好的颜色输出到屏幕！
                return i.myColor;
                
                //进阶：z-buffer
                // i.vertex.z 存储了该像素在裁剪空间下的深度值
                // 取值范围根据平台不同可能不同，但在 PC 上通常是非线性映射的数值
                // 我们直接把它当成灰度颜色输出（红绿蓝三个通道给一样的值就是灰度）
                //fixed depth = i.vertex.z / i.vertex.w; // 除以 w 进行透视除法，归一化到 0-1 (近似)

                //return fixed4(depth, depth, depth, 1.0);
            }
            ENDCG
        }
    }
}