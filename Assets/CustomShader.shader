Shader "Unlit/CustomShader"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1, 1, 0, 1) // Yellow
        _Color2 ("Color 2", Color) = (1, 0, 1, 1) // Pink
        _Color3 ("Color 3", Color) = (1, 0, 0, 1) // Red
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseFrequency ("Noise Frequency", Float) = 1.0
        _WaveAmplitude ("Wave Amplitude", Float) = 0.1
        _WaveFrequency ("Wave Frequency", Float) = 1.0
        _Speed ("Speed", Float) = 1.0
        _Displacement ("Displacement Amount", Float) = 0.1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 200
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
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
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _NoiseScale;
            float _NoiseFrequency;
            float _WaveAmplitude;
            float _WaveFrequency;
            float _Speed;
            float _Displacement;

            // Noise function
            float noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                // Calculate time-based phase shift
                float phase = _Time.y * _Speed;

                // Apply figure-eight motion
                worldPos.x += sin(phase) * _WaveAmplitude;
                worldPos.z += sin(2 * phase) * _WaveAmplitude;

                // Apply wave animation to the y-coordinate
                worldPos.y += _WaveAmplitude * sin(_WaveFrequency * worldPos.x + phase);

                // Generate procedural noise with frequency control
                float noiseValue = noise(v.uv * _NoiseFrequency * _NoiseScale + _Time.y * _Speed);

                // Displace vertices along the normal direction based on noise
                float3 normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                worldPos.xyz += normal * noiseValue * _Displacement;

                o.pos = UnityObjectToClipPos(worldPos);
                o.uv = v.uv;
                o.worldPos = worldPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Generate procedural noise with frequency control
                float n = noise(i.uv * _NoiseFrequency * _NoiseScale + _Time.y * _Speed);

                // Adjust alpha based on noise value to create transparency effect
                float alpha = n;

                // Cycle through colors: _Color1, _Color2, _Color3
                float t = frac(_Time.y);
                float3 color;

                if (t < 0.33)
                {
                    // Interpolate from _Color1 to _Color2
                    color = lerp(_Color1.rgb, _Color2.rgb, t / 0.33);
                }
                else if (t < 0.66)
                {
                    // Interpolate from _Color2 to _Color3
                    color = lerp(_Color2.rgb, _Color3.rgb, (t - 0.33) / 0.33);
                }
                else
                {
                    // Interpolate from _Color3 to _Color1
                    color = lerp(_Color3.rgb, _Color1.rgb, (t - 0.66) / 0.34);
                }

                // Set the final color with adjusted alpha
                fixed4 finalColor = fixed4(color, alpha);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
