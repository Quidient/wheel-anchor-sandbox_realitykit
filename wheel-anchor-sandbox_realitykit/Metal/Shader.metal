#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;



[[visible]]
void futuristicTessellationShader(realitykit::surface_parameters params)
{
    // Base color with slight transparency
    half4 baseColor = half4(0.1, 0.5, 0.9, 0.9);
    
    //Triangle size values between 1.0 - 20.0, smaller tesselation scale larger triangles
    float tessellationScale = 2.0;
    
    // Get position and normal
    float3 worldPosition = params.geometry().world_position();
    float3 normal = params.geometry().normal();
    
    // Create tessellation pattern
    float3 scaledPos = worldPosition * tessellationScale;
    float pattern = fract(sin(dot(floor(scaledPos), float3(12.9898, 78.233, 45.164))) * 43758.5453);
    
    // Create edge highlighting
    float edgeFactor = 1.0 - abs(dot(normal, normalize(float3(1.0, 1.0, 1.0))));
    float edge = smoothstep(0.3, 0.7, edgeFactor);
    
    // Create pulse effect based on time
    float time = params.uniforms().time();
    float pulse = 0.5 + 0.5 * sin(time * 0.5);
    
    // Apply tessellation and edge glow
    half3 tessColor = mix(baseColor.rgb, half3(0.2, 0.8, 1.0), half(pattern * 0.5));
    half3 edgeColor = half3(0.3, 0.8, 1.0) * half(edge * pulse);
    
    // Set surface properties
    params.surface().set_base_color(tessColor);
    params.surface().set_opacity(baseColor.a);
    params.surface().set_emissive_color(edgeColor);
    params.surface().set_roughness(0.2);
    params.surface().set_metallic(0.8);
}

[[visible]]
void simpleMeshModifier(realitykit::geometry_parameters params)
{
    
    // Get position
    float3 position = params.geometry().model_position();
    float time = params.uniforms().time();
    
    // Subtle vertex displacement based on position and time
    float displacement = sin(position.x * 4.0 + time) * sin(position.y * 4.0 + time) * 0.001;
    
    // Apply displacement along normal
    float3 normal = params.geometry().normal();
    
    params.geometry().set_model_position_offset(normal * displacement);
}
