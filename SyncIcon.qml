import QtQuick
import QtQuick.Shapes

// Theme-aware vector mark for Settings Sync.
// Same artwork as icon.svg, drawn with Shape so `color` follows the bar
// and theme instead of baking in a fixed fill.

Item {
  id: root

  property color color: "white"

  implicitWidth: 24
  implicitHeight: 24

  Shape {
    id: shape
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    // The artwork lives in a 24x24 design space; scale it onto the canvas.
    // Scale.origin defaults to (0, 0), so the mark stays top-left aligned
    // while it grows to fill.
    transform: Scale {
      xScale: shape.width > 0 ? shape.width / 24 : 1
      yScale: shape.height > 0 ? shape.height / 24 : 1
    }

    ShapePath {
      fillColor: root.color
      strokeColor: "transparent"

      PathSvg {
        path: "M20 22H4v-2h2v-6h2v6h8v-6h2v6h2zM4 20H2V4h2zm18 0h-2V6h2zm-6-6H8v-2h8zm-4-4H6V6h6zm8-4h-2V4h2zm-2-2H4V2h14z"
      }
    }
  }
}
