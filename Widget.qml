import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

// Settings Sync — bar widget + popup panel in one file.
//
// All real work happens in bin/settings-sync-ctl next to this file.
// This UI only shows `status --json` and runs backup/restore/set-repo,
// then refreshes. The CLI is also usable directly in a terminal, which is
// the documented fresh-install recovery path.

Panel {
  id: root
  moduleName: "settings-sync"
  ipcTarget: "settings-sync"

  readonly property string ctl: {
    var url = Qt.resolvedUrl("bin/settings-sync-ctl").toString()
    return url.indexOf("file://") === 0 ? url.substring(7) : "settings-sync-ctl"
  }

  readonly property var syncState: Model.parseStatus(statusProc.text)
  readonly property bool busy: backupProc.running || restoreProc.running

  property string repoDraft: ""
  property string lastMessage: ""
  property string messageKind: "info" // info | working | ok | error
  property string lastOp: "" // backup | restore — which action produced the current status
  property bool showRepoEditor: false

  // The exact line a fresh machine needs; copied to the clipboard on demand.
  readonly property string restoreCommand: root.syncState.hasRepo
    ? "settings-sync-ctl restore --repo " + root.syncState.repo + " --yes"
    : ""

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  Component.onCompleted: refresh()
  onOpenedChanged: {
    if (opened) {
      root.repoDraft = root.syncState.repo
      root.showRepoEditor = !root.syncState.hasRepo
      refresh()
    }
  }

  function runBackup() {
    if (root.busy) return
    root.lastOp = "backup"
    root.messageKind = "working"
    root.lastMessage = ""
    backupProc.command = [root.ctl, "backup", "--push"]
    backupProc.running = true
  }

  function runRestore() {
    if (root.busy) return
    root.lastOp = "restore"
    root.messageKind = "working"
    root.lastMessage = ""
    restoreProc.command = [root.ctl, "restore", "--yes"]
    restoreProc.running = true
  }

  function saveRepo() {
    if (setRepoProc.running || root.repoDraft === "") return
    setRepoProc.command = [root.ctl, "set-repo", root.repoDraft]
    setRepoProc.running = true
  }

  function copyRestoreCommand() {
    if (root.restoreCommand === "" || copyProc.running) return
    copyProc.secret = root.restoreCommand
    copyProc.running = true
    root.messageKind = "info"
    root.lastMessage = "Restore command copied to clipboard"
  }

  // The exit code arrives as an onExited signal argument (kit convention) —
  // there is no exitCode property to read afterwards.
  function finishRun(op, exitCode, exitStatus, errText, okText) {
    root.lastOp = op
    if (exitCode === 0 && exitStatus === 0) {
      root.messageKind = "ok"
      root.lastMessage = okText
    } else {
      root.messageKind = "error"
      var detail = (errText || "").trim().split("\n").slice(-2).join(" ")
      root.lastMessage = detail !== "" ? detail : "Failed with exit code " + exitCode
    }
    root.refresh()
  }

  function messageColor() {
    if (root.messageKind === "error") return Color.urgent
    if (root.messageKind === "ok") return root.successGreen()
    if (root.messageKind === "working") return root.bar.foreground
    return Qt.darker(root.bar.foreground, 1.4)
  }

  // The asked-for green, picked for contrast against the bar background so
  // the success state stays readable on light and dark themes alike.
  function successGreen() {
    var bg = root.bar ? root.bar.background : "#000000"
    var lum = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b
    return lum > 0.6 ? "#1e7e34" : "#7bd88a"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: Model.tooltipText(root.syncState)
    iconComponent: Component {
      SyncIcon {
        color: button.foreground
      }
    }
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(panelBody.implicitHeight, Style.space(600))

    Item {
      id: panelBody
      width: parent.width
      implicitHeight: panelColumn.implicitHeight

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.spacing.md

        PanelHero {
          width: parent.width
          title: "Settings Sync"
          meta: Model.statusLine(root.syncState)
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          iconComponent: Component {
            SyncIcon {
              width: Style.font.display
              height: Style.font.display
              color: root.bar.foreground
            }
          }
          trailingControl: Component {
            Button {
              tooltipText: "Refresh status"
              iconText: "󰑓"
              enabled: !statusProc.running
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onClicked: root.refresh()
            }
          }
        }

        // --- empty state: no repo yet ----------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.sm
          visible: !root.syncState.hasRepo

          Text {
            width: parent.width
            text: "Back up plugins, layout, theme and configs to a git repo, then restore them on a fresh install. Start with the repo:"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          TextField {
            width: parent.width
            text: root.repoDraft
            placeholderText: "git@github.com:you/omarchy-backup.git"
            font.family: root.bar.fontFamily
            onTextChanged: root.repoDraft = text
            onAccepted: root.saveRepo()
          }

          Button {
            text: "Save repo"
            selected: true
            enabled: root.repoDraft !== "" && !setRepoProc.running
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.saveRepo()
          }
        }

        // --- backup ------------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo

          PanelSectionHeader {
            width: parent.width
            text: "Backup"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            width: parent.width
            spacing: Style.spacing.sm

            Text {
              width: parent.width - changeBtn.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: Model.shortRepo(root.syncState.repo)
              color: Qt.darker(root.bar.foreground, 1.3)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideMiddle
            }

            Button {
              id: changeBtn
              text: "Change"
              enabled: !root.busy
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onClicked: {
                root.repoDraft = root.syncState.repo
                root.showRepoEditor = !root.showRepoEditor
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.sm
            visible: root.showRepoEditor

            TextField {
              width: parent.width
              text: root.repoDraft
              font.family: root.bar.fontFamily
              onTextChanged: root.repoDraft = text
              onAccepted: root.saveRepo()
            }

            Row {
              width: parent.width
              spacing: Style.spacing.sm

              Button {
                text: "Save"
                selected: true
                enabled: root.repoDraft !== "" && !setRepoProc.running
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.saveRepo()
              }

              Button {
                text: "Cancel"
                enabled: !setRepoProc.running
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.showRepoEditor = false
              }
            }
          }

          Text {
            width: parent.width
            text: root.syncState.pluginCount + " plugins · " + (root.syncState.theme || "—")
              + (root.syncState.hasBackup && root.syncState.lastBackup !== ""
                ? "\nLast backup " + root.syncState.lastBackup
                  + (root.syncState.lastBackupHost ? " on " + root.syncState.lastBackupHost : "")
                : "\nNo backup yet")
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          // The backup action carries its state inside its own button: the
          // Button owns every interaction state (hover, pressed, disabled)
          // while this overlay only paints the vector icon + label. Plain
          // Items never accept mouse input, so clicks fall through to the
          // Button's own MouseArea. The Button's text stays empty so its
          // internal row collapses and the overlay is the only content.
          Button {
            id: backupBtn
            width: parent.width
            // The Button sizes itself from its (empty) internal row, so pin
            // the height to the kit's own formula driven by the real overlay
            // content: content + vertical padding + reserved borders.
            height: stateRow.implicitHeight + verticalPadding * 2
              + _reservedBorderTop + _reservedBorderBottom
            text: ""
            selected: true
            enabled: !root.busy
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.runBackup()

            readonly property color labelColor: Style.selectedStateColor(foreground, accent)
            readonly property string stateLabel: backupProc.running ? "Backing up…"
              : (root.lastOp === "backup" && root.messageKind === "ok" ? "Backup done!" : "Back up now")
            readonly property bool showSmiley: !backupProc.running
              && root.lastOp === "backup" && root.messageKind === "ok"

            Item {
              anchors.fill: parent
              opacity: parent.enabled ? 1 : 0.45

              Row {
                id: stateRow
                anchors.centerIn: parent
                spacing: Style.spacing.controlGap

                Item {
                  width: Style.space(16)
                  height: Style.space(16)
                  anchors.verticalCenter: parent.verticalCenter
                  visible: backupProc.running || backupBtn.showSmiley

                  SpinnerIcon {
                    anchors.fill: parent
                    visible: backupProc.running
                    spinning: root.opened
                    color: backupBtn.labelColor
                  }

                  SmileyIcon {
                    anchors.fill: parent
                    visible: backupBtn.showSmiley
                    color: root.successGreen()
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  text: backupBtn.stateLabel
                  color: backupBtn.labelColor
                  font.family: backupBtn.fontFamily
                  font.pixelSize: backupBtn.fontSize
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.bar.foreground
          visible: root.syncState.hasRepo
        }

        // --- restore -------------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo

          PanelSectionHeader {
            width: parent.width
            text: "Restore"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Button {
            width: parent.width
            text: restoreProc.running ? "Restoring…" : "Restore from backup"
            bordered: true
            enabled: !root.busy
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.runRestore()
          }

          Text {
            width: parent.width
            text: "Reinstalls plugins and overwrites local configs. Your current setup is snapshotted first."
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.bar.foreground
          visible: root.syncState.hasRepo
        }

        // --- fresh install ---------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo

          PanelSectionHeader {
            width: parent.width
            text: "Fresh install"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.restoreCommand
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WrapAnywhere
          }

          Button {
            text: "Copy restore command"
            iconText: "󰆏"
            enabled: !copyProc.running
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.copyRestoreCommand()
          }
        }

        // --- status ------------------------------------------------------------
        // Backup carries its state in its own row (spinner while working,
        // green smiley once done). This line is for everything else: errors
        // in urgent red, restore results, and confirmations.
        Row {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo && root.lastMessage !== ""
            && !(root.messageKind === "ok" && root.lastOp === "backup")

          SmileyIcon {
            width: Style.space(16)
            height: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.messageKind === "ok"
            color: root.successGreen()
          }

          Text {
            width: parent.width - (root.messageKind === "ok" ? Style.space(16) + parent.spacing : 0)
            text: root.lastMessage
            color: root.messageColor()
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  // --- backend processes --------------------------------------------

  Process {
    id: statusProc
    command: [root.ctl, "status", "--json"]
    property string text: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: statusProc.text = text
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: backupProc
    property string err: ""
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: backupProc.err = text
    }
    onExited: function(exitCode, exitStatus) {
      root.finishRun("backup", exitCode, exitStatus, backupProc.err, "Backup complete and pushed.")
    }
  }

  Process {
    id: restoreProc
    property string err: ""
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: restoreProc.err = text
    }
    onExited: function(exitCode, exitStatus) {
      root.finishRun("restore", exitCode, exitStatus, restoreProc.err, "Restore complete.")
    }
  }

  Process {
    id: setRepoProc
    onRunningChanged: {
      if (running) return
      root.showRepoEditor = false
      root.refresh()
    }
  }

  Process {
    id: copyProc
    command: ["wl-copy"]
    property string secret: ""
    stdinEnabled: true
    onStarted: {
      write(secret)
      secret = ""
      stdinEnabled = false
    }
  }
}
