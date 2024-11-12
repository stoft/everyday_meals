import lustre/attribute.{type Attribute, attribute}
import lustre/element/svg

pub fn languages(attributes: List(Attribute(a))) {
  svg.svg(
    [
      attribute("stroke-linejoin", "round"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-width", "2"),
      attribute("stroke", "currentColor"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("height", "24"),
      attribute("width", "24"),
      ..attributes
    ],
    [
      svg.path([attribute("d", "m5 8 6 6")]),
      svg.path([attribute("d", "m4 14 6-6 2-3")]),
      svg.path([attribute("d", "M2 5h12")]),
      svg.path([attribute("d", "M7 2h1")]),
      svg.path([attribute("d", "m22 22-5-10-5 10")]),
      svg.path([attribute("d", "M14 18h6")]),
    ],
  )
}
