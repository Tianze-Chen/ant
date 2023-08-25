#include <bgfx_shader.sh>
#include "common/transform.sh"
#include "common/common.sh"
#include "default/inputs_structure.sh"

void CUSTOM_VS_FUNC(in VSInput vs_input, inout VSOutput vs_output)
{
	vs_output.uv0	= vs_input.uv0;
#ifdef USING_LIGHTMAP
	vs_output.uv1 = vs_input.uv1;
#endif //USING_LIGHTMAP

#ifdef WITH_COLOR_ATTRIB
	vs_output.color = vs_input.color;
#endif //WITH_COLOR_ATTRIB

#ifndef MATERIAL_UNLIT
	mat4 wm = get_world_matrix(vs_input);
	vec4 posWS = transform_pos(wm, vs_input.pos, vs_output.clip_pos);
	vs_output.world_pos = posWS;
	vs_output.world_pos.w = mul(u_view, vs_output.world_pos).z;

#ifdef CALC_TBN
	vs_output.normal	= mul(wm, vec4(vs_input.normal, 0.0)).xyz;
#else //!CALC_TBN
#	if PACK_TANGENT_TO_QUAT
	const mediump vec4 quat = vs_input.tangent;
	mediump vec3 normal = quat_to_normal(quat);
	mediump vec3 tangent = quat_to_tangent(quat);
#	else //!PACK_TANGENT_TO_QUAT
	mediump vec3 normal = vs_input.normal;
	mediump vec3 tangent = vs_input.tangent.xyz;
#	endif//PACK_TANGENT_TO_QUAT
	vs_output.normal	= mul(wm, mediump vec4(normal, 0.0)).xyz;
	vs_output.tangent	= mul(wm, mediump vec4(tangent, 0.0)).xyz * sign(vs_input.tangent.w);
#endif//CALC_TBN

#endif //!MATERIAL_UNLIT
}