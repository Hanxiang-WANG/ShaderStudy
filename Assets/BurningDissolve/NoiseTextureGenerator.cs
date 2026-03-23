using UnityEngine;
using UnityEditor;
using System.IO;

public class NoiseTextureGenerator : EditorWindow
{
    private string textureName = "ProceduralNoise";
    private int textureSize = 512;
    // 缩放比例，数值越小，噪波越“大块、平滑”；数值越大，噪波越“细碎”
    private float noiseScale = 10.0f; 

    [MenuItem("Tools/Generate Dissolve Noise")]
    public static void ShowWindow()
    {
        GetWindow<NoiseTextureGenerator>("Noise Generator");
    }

    private void OnGUI()
    {
        GUILayout.Label("Generate a random Perlin noise texture for dissolve effects.", EditorStyles.boldLabel);
        textureName = EditorGUILayout.TextField("Texture Name", textureName);
        textureSize = EditorGUILayout.IntField("Texture Size", textureSize);
        noiseScale = EditorGUILayout.Slider("Noise Scale", noiseScale, 1.0f, 50.0f);

        if (GUILayout.Button("Generate and Save"))
        {
            GenerateAndSaveNoise();
        }
    }

    private void GenerateAndSaveNoise()
    {
        // 1. 创建一个新的 Texture2D (单通道灰度图即可，节省显存)
        Texture2D noiseTex = new Texture2D(textureSize, textureSize, TextureFormat.R8, false, true);
        Color[] pixels = new Color[textureSize * textureSize];

        // 随机一个偏移量，确保每次生成的图案都不一样
        float offsetX = Random.Range(0f, 10000f);
        float offsetY = Random.Range(0f, 10000f);

        // 2. 遍历像素，计算柏林噪声值
        for (int y = 0; y < textureSize; y++)
        {
            for (int x = 0; x < textureSize; x++)
            {
                // 计算采样坐标，缩放并加入随机偏移
                float xCoord = (float)x / textureSize * noiseScale + offsetX;
                float yCoord = (float)y / textureSize * noiseScale + offsetY;

                // Unity 内置了计算 2D 柏林噪声的数学函数，范围是 [0, 1]
                float sample = Mathf.PerlinNoise(xCoord, yCoord);

                // 将噪声值作为灰度赋给像素
                pixels[y * textureSize + x] = new Color(sample, sample, sample, 1.0f);
            }
        }

        noiseTex.SetPixels(pixels);
        noiseTex.Apply();

        // 3. 保存为 PNG 文件
        byte[] bytes = noiseTex.EncodeToPNG();
        string fileName = textureName + ".png";
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
                // 溶解遮罩不需要 Mipmap，必须是 Clamp
                importer.sRGBTexture = false; // 噪波属于数据贴图，不是颜色，关闭 sRGB
                importer.mipmapEnabled = false; 
                importer.wrapMode = TextureWrapMode.Clamp; 
                importer.SaveAndReimport();
                Debug.Log("完美的程序化噪波纹理已生成并在材质面板配置完毕！路径: " + assetPath);
            }
        };
        
        Close(); // 关闭窗口
    }
}