import QtQuick

// Twelve-dot loading spinner (see spinner.svg for the static artwork).
// SMIL animations in SVG do not run in QML, so the chase is driven here:
// a timer advances the head dot and the trail fades behind it.

Item {
  id: root

  property color color: "white"
  property bool spinning: true

  implicitWidth: 24
  implicitHeight: 24

  property int frame: 0

  Timer {
    interval: 90
    repeat: true
    running: root.spinning
    onTriggered: root.frame = (root.frame + 1) % 12
  }

  Item {
    id: dots
    anchors.fill: parent

    transform: Scale {
      xScale: dots.width > 0 ? dots.width / 24 : 1
      yScale: dots.height > 0 ? dots.height / 24 : 1
    }

    Repeater {
      model: 12

      Rectangle {
        // Ring geometry matches spinner.svg: radius 8.5, dot radius 1.5,
        // head at twelve o'clock, running clockwise.
        readonly property real angle: (-90 + index * 30) * Math.PI / 180
        x: 12 + 8.5 * Math.cos(angle) - 1.5
        y: 12 + 8.5 * Math.sin(angle) - 1.5
        width: 3
        height: 3
        radius: 1.5
        color: root.color

        // Comet trail behind the head dot.
        readonly property int age: (root.frame - index + 24) % 12
        opacity: age === 0 ? 1 : Math.max(0.12, 1 - age * 0.09)
      }
    }
  }
}
