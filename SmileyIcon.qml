import QtQuick
import QtQuick.Shapes

// Success smiley for Settings Sync. Same artwork as smiley.svg (kept next
// to this file as the source art), drawn with Shape so `color` follows the
// caller instead of baking in a fixed fill.

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
        path: "M10.25 10a1.25 1.25 0 1 0-2.499 0a1.25 1.25 0 0 0 2.499 0m6 0a1.25 1.25 0 1 0-2.499 0a1.25 1.25 0 0 0 2.499 0m-6.114 5.106a.75.75 0 0 0-.772 1.286c.767.46 1.72.67 2.636.67s1.87-.21 2.636-.67a.75.75 0 1 0-.772-1.286c-.483.29-1.154.456-1.864.456s-1.38-.166-1.864-.456M22.002 12c0-5.524-4.478-10.002-10.002-10.002S2 6.476 2 12c-.001 5.523 4.476 10 10 10s10.002-4.477 10.002-10M3.499 12a8.502 8.502 0 1 1 17.003 0a8.502 8.502 0 0 1-17.003 0"
      }
    }
  }
}
