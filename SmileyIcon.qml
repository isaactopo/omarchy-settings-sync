import QtQuick
import QtQuick.Shapes

// Small drawn smiley for success states. Vector like SyncIcon so it stays
// crisp at any size and takes any color (no font-glyph costume).

Item {
  id: root

  property color color: "white"

  implicitWidth: 16
  implicitHeight: 16

  Shape {
    id: shape
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
      xScale: shape.width > 0 ? shape.width / 16 : 1
      yScale: shape.height > 0 ? shape.height / 16 : 1
    }

    // Face outline.
    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: 1.5

      PathSvg {
        path: "M1.5 8 a6.5 6.5 0 1 0 13 0 a6.5 6.5 0 1 0 -13 0"
      }
    }

    // Smile: quadratic through a below-center control point, so the curve
    // always dips down no matter the arc-flag reading.
    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: 1.5
      capStyle: ShapePath.RoundCap
      startX: 5
      startY: 9.3

      PathQuad {
        x: 11
        y: 9.3
        controlX: 8
        controlY: 12.6
      }
    }
    // Eyes: filled dots in the same scaled space, so they track the face
    // at any size.
    ShapePath {
      fillColor: root.color
      strokeColor: "transparent"

      PathSvg {
        path: "M5 6.2 a0.8 0.8 0 1 0 1.6 0 a0.8 0.8 0 1 0 -1.6 0 M9.4 6.2 a0.8 0.8 0 1 0 1.6 0 a0.8 0.8 0 1 0 -1.6 0"
      }
    }
  }
}
