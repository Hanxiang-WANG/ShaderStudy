using UnityEngine;
using UnityEditor;
using System.IO;

public class RampGenerator : EditorWindow
{
    [MenuItem("Tools/Generate Blue-Pink Ramp")]
    public static void GenerateRamp()
    {
        int width = 256;
        int height = 16;
        
        // 1. 创建纹理 (关闭 Mipmap，线性颜色空间)
        Texture2D rampTex = new Texture2D(width, height, TextureFormat.RGBA32, false, true);
        
        // 自定义颜色：左边深蓝，右边粉红
        Color colorLeft = new Color(0.1f, 0.2f, 0.8f); // 深蓝色
        Color colorRight = new Color(1.0f, 0.4f, 0.7f); // 粉红色

        // 2. 遍历像素，计算渐变色
        for (int x = 0; x < width; x++)
        {
            // 计算当前像素的进度 (0 到 1)
            float t = (float)x / (width - 1);
            
            // 线性插值混合颜色
            Color pixelColor = Color.Lerp(colorLeft, colorRight, t);

            for (int y = 0; y < height; y++)
            {
                rampTex.SetPixel(x, y, pixelColor);
            }
        }

        rampTex.Apply();

        // 3. 保存为 PNG 文件
        byte[] bytes = rampTex.EncodeToPNG();
        string fileName = "BluePinkRamp.png";
        string path = Path.Combine(Application.dataPath, fileName);
        File.WriteAllBytes(path, bytes);

        // 4. 刷新并自动设置导入器 (极其重要！)
        AssetDatabase.Refresh();
        
        EditorApplication.delayCall += () =>
        {
            string assetPath = "Assets/" + fileName;
            TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
            if (importer != null)
            {
                importer.sRGBTexture = true; // 颜色贴图需要 sRGB
                importer.mipmapEnabled = false; // 渐变图绝不需要 Mipmap
                importer.wrapMode = TextureWrapMode.Clamp; // 【核心】必须是 Clamp，防止光照边缘溢出
                importer.textureCompression = TextureImporterCompression.Uncompressed; // 保持最高精度
                importer.SaveAndReimport();
                Debug.Log("完美的蓝粉渐变纹理已生成并设置完毕！路径: " + assetPath);
            }
        };
    }
}