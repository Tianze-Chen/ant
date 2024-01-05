#include <css/Property.h>

namespace Rml {

struct InterpolateVisitor {
	const PropertyVariant& other_variant;
	float alpha;
	template <typename T>
	Property operator()(const T& p0) {
		return interpolate(p0, std::get<T>(other_variant));
	}

	template <typename T>
	T interpolate(const T& p0, const T& p1) {
		return InterpolateFallback(p0, p1, alpha);
	}
};

template<>
PropertyFloat InterpolateVisitor::interpolate<PropertyFloat>(const PropertyFloat& p0, const PropertyFloat& p1) {
	return p0.Interpolate(p1, alpha);
}
template<>
Color InterpolateVisitor::interpolate<Color>(const Color& p0, const Color& p1) {
	return p0.Interpolate(p1, alpha);
}
template<>
Transform InterpolateVisitor::interpolate<Transform>(const Transform& p0, const Transform& p1) {
	return p0.Interpolate(p1, alpha);
}

Property Property::Interpolate(const Property& other, float alpha) const {
	if (index() != other.index()) {
		return InterpolateFallback(*this, other, alpha);
	}
	return std::visit(InterpolateVisitor{ other, alpha }, (const PropertyVariant&)*this);
}

}
