// Written in CG that is based on HLSL, so it is compatible on different platforms (Unity-Cross-Platform)
Shader "Unlit/CustomShader"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1, 1, 0, 1) // Yellow
        _Color2 ("Color 2", Color) = (1, 0, 1, 1) // Pink
        _Color3 ("Color 3", Color) = (1, 0, 0, 1) // Red
        _Transparency ("Transparency", Range(0, 1)) = 1.0 // Slider to control transparency
        _ColorChangeSpeed ("Color Change Speed", Float) = 1.0 // Speed of color changing
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseFrequency ("Noise Frequency", Float) = 1.0
        _WaveAmplitude ("Wave Amplitude", Float) = 0.1
        _WaveFrequency ("Wave Frequency", Float) = 1.0
        _Speed ("Speed", Float) = 1.0
        _Displacement ("Displacement Amount", Float) = 0.1
        _SpecularPower ("Specular Power", Range(0.1, 100)) = 10.0 // Specular highlight power
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.5 // Strength of shadow effect
        _RefractionStrength ("Refraction Strength", Range(0, 1)) = 0.5 // Strength of refraction effect
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.5 // Strength of reflection effect
        _DistortionScale ("Distortion Scale", Float) = 0.1 // Scale of distortion effect
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

            // Define a variable to store the camera distance
            float _CameraDistance;

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
                float3 normal : TEXCOORD2;
            };

            // Properties
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _Transparency;
            float _ColorChangeSpeed;
            float _NoiseScale;
            float _NoiseFrequency;
            float _WaveAmplitude;
            float _WaveFrequency;
            float _Speed;
            float _Displacement;
            float _SpecularPower;
            float _ShadowStrength;
            float _RefractionStrength;
            float _ReflectionStrength;
            float _DistortionScale;

            // Noise function
            float noise(float2 uv)
            {
                // Define magic numbers (predefined constants) used in the noise calculation
                float2 magicNumbers = float2(12.9898, 78.233);

                // Calculate the dot product of the input UV coordinates and the magic numbers
                float dotProduct = dot(uv, magicNumbers);

                // Compute the sine of the dot product
                float sinResult = sin(dotProduct);

                // Scale and clamp the sine result to the range [0, 1] to obtain the noise value
                float noiseValue = frac(sinResult * 43758.5453);

                // Return the computed noise value
                return noiseValue;
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

                // Calculate camera distance
                _CameraDistance = length(UnityObjectToViewPos(worldPos));

                // Adjust displacement based on camera distance
                float displacementFactor = 2.0 / (_CameraDistance + 0.01); // Adding a small value to avoid division by zero

                // Displace vertices along the normal direction based on noise and displacement factor
                float3 normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                worldPos.xyz += normal * noiseValue * _Displacement * displacementFactor;

                o.pos = UnityObjectToClipPos(worldPos);
                o.uv = v.uv;
                o.worldPos = worldPos;
                o.normal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Generate procedural noise with frequency control
                float n = noise(i.uv * _NoiseFrequency * _NoiseScale + _Time.y * _Speed);

                // Adjust alpha based on noise value to create transparency effect
                float alpha = n * _Transparency;

                // Cycle through colors: _Color1, _Color2, _Color3
                float t = frac(_Time.y * _ColorChangeSpeed);
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

                // Apply lighting calculations
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));
                float3 lightDir = float3(0.5, 0.5, -1); // Example directional light direction
                float3 reflectDir = reflect(-lightDir, normal);

                float diffuse = max(dot(normal, lightDir), 0);
                float specular = pow(max(dot(reflectDir, viewDir), 0), _SpecularPower);

                // Apply shadow mapping
                float shadowFactor = _ShadowStrength; // Placeholder for shadow strength calculation

                // Apply reflection and refraction
                float reflectionFactor = _ReflectionStrength; // Placeholder for reflection strength calculation
                float refractionFactor = _RefractionStrength; // Placeholder for refraction strength calculation

                // Apply distortion effects
                float2 distortionUV = i.uv + _Time.y * _DistortionScale;
                float distortion = noise(distortionUV) * _DistortionScale;

                // Combine lighting, shadow, reflection, and distortion
                float3 finalColor = color * (diffuse + specular) * (1 - shadowFactor) * (1 - reflectionFactor) * (1 - refractionFactor) + distortion;

                // Set the final color with adjusted alpha
                fixed4 finalColorWithAlpha = fixed4(finalColor, alpha);

                return finalColorWithAlpha;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

