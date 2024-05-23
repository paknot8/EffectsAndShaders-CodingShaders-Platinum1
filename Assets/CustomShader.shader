Shader "Unlit/CustomShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NoiseScale ("Noise Scale", Float) = 1.0
        _WaveAmplitude ("Wave Amplitude", Float) = 0.1
        _WaveFrequency ("Wave Frequency", Float) = 1.0
        _Speed ("Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
            };

            // Properties
            float4 _Color;
            float _NoiseScale;
            float _WaveAmplitude;
            float _WaveFrequency;
            float _Speed;

            // Noise function
            float noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                // Apply wave animation
                worldPos.y += _WaveAmplitude * sin(_WaveFrequency * worldPos.x + _Time.y * _Speed);
                
                o.pos = UnityObjectToClipPos(worldPos);
                o.uv = v.uv;
                o.worldPos = worldPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Generate procedural noise
                float n = noise(i.uv * _NoiseScale + _Time.y * _Speed);

                // Combine noise with base color
                fixed4 color = _Color * n;

                return color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
