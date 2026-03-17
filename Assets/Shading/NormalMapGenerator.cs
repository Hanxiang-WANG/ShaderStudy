using UnityEngine;
using UnityEditor;
using System.IO;

public class NormalMapGenerator : EditorWindow
{
    private string textureName = "ProceduralNormalMap";
    private int textureSize = 512;

    [MenuItem("Tools/Generate Experimental Normal Map")]
    public static void ShowWindow()
    {
        GetWindow<NormalMapGenerator>("Normal Map Generator");
    }

    private void OnGUI()
    {
        GUILayout.Label("Generate a distinct normal map for testing.", EditorStyles.boldLabel);
        textureName = EditorGUILayout.TextField("Texture Name", textureName);
        textureSize = EditorGUILayout.IntField("Texture Size", textureSize);

        if (GUILayout.Button("Generate and Save"))
        {
            GenerateAndSaveNormalMap();
        }
    }

    private void GenerateAndSaveNormalMap()
    {
        // 1. 创建一个新的 Texture2D，使用 RGBA32 格式
        Texture2D normalMap = new Texture2D(textureSize, textureSize, TextureFormat.RGBA32, false);
        Color[] pixels = new Color[textureSize * textureSize];

        float center = textureSize / 2.0f;
        float invSize = 1.0f / textureSize;

        for (int y = 0; y < textureSize; y++)
        {
            for (int x = 0; x < textureSize; x++)
            {
                // 默认法线：笔直向上 (0, 0, 1)
                // 映射到颜色：(0.5, 0.5, 1.0) -> 蓝紫色
                float nx = 0.0f;
                float ny = 0.0f;
                float nz = 1.0f;

                // --- 开始设计图案 ---

                // 图案 1：中间一个凸起的十字形
                float thickness = textureSize * 0.1f;
                float length = textureSize * 0.4f;

                bool inHorizontalBar = (x >= center - length && x <= center + length) && (y >= center - thickness && y <= center + thickness);
                bool inVerticalBar = (x >= center - thickness && x <= center + thickness) && (y >= center - length && y <= center + length);

                if (inHorizontalBar || inVerticalBar)
                {
                    // 在十字形内部，我们让法线根据其在十字形内的位置发生倾斜
                    // 模拟一个斜坡
                    float pctX = (x - center) / length;
                    float pctY = (y - center) / length;

                    // 十字形的法线向四周倾斜
                    nx = Mathf.Clamp(pctX * 0.8f, -0.8f, 0.8f);
                    ny = Mathf.Clamp(pctY * 0.8f, -0.8f, 0.8f);
                    // 确保法线是归一化的 (长度为1)
                    nz = Mathf.Sqrt(1.0f - nx * nx - ny * ny);
                }
                
                // 图案 2：四个凹下去的圆点
                float dotRadius = textureSize * 0.08f;
                float dotOffset = textureSize * 0.25f;
                Vector2[] dotCenters = new Vector2[]
                {
                    new Vector2(center - dotOffset, center - dotOffset),
                    new Vector2(center + dotOffset, center - dotOffset),
                    new Vector2(center - dotOffset, center + dotOffset),
                    new Vector2(center + dotOffset, center + dotOffset)
                };

                foreach (Vector2 dotCenter in dotCenters)
                {
                    float dist = Vector2.Distance(new Vector2(x, y), dotCenter);
                    if (dist <= dotRadius)
                    {
                        // 在圆点内部，模拟一个碗状的凹陷
                        // 法线向圆心倾斜
                        float pctX = (x - dotCenter.x) / dotRadius;
                        float pctY = (y - dotCenter.y) / dotRadius;

                        // 凹陷的法线向内倾斜 (注意符号与凸起相反)
                        nx = -pctX * 0.7f;
                        ny = -pctY * 0.7f;
                        nz = Mathf.Sqrt(1.0f - nx * nx - ny * ny);
                    }
                }

                // --- 结束设计图案 ---

                // 2. 将法线方向 [-1, 1] 映射到颜色空间 [0, 1]
                // 公式: Color = (Normal + 1) / 2
                float r = (nx + 1.0f) * 0.5f;
                float g = (ny + 1.0f) * 0.5f;
                float b = (nz + 1.0f) * 0.5f;

                pixels[y * textureSize + x] = new Color(r, g, b, 1.0f);
            }
        }

        // 3. 将像素数据应用到纹理
        normalMap.SetPixels(pixels);
        normalMap.Apply();

        // 4. 将纹理保存为 PNG 文件
        byte[] bytes = normalMap.EncodeToPNG();
        string path = Path.Combine(Application.dataPath, textureName + ".png");
        File.WriteAllBytes(path, bytes);

        // 5. 刷新 AssetDatabase，让 Unity 编辑器识别新文件
        AssetDatabase.Refresh();

        // 6. 自动将新生成的纹理类型设置为 'Normal map'
        string assetPath = "Assets/" + textureName + ".png";
        TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (importer != null)
        {
            importer.textureType = TextureImporterType.NormalMap;
            importer.SaveAndReimport();
        }

        Debug.Log("Normal map generated and saved to: " + path);
        Close(); // 关闭窗口
    }
}