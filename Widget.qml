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
  property bool showRepoEditor: false

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
    root.lastMessage = "Backing up…"
    backupProc.command = [root.ctl, "backup", "--push"]
    backupProc.running = true
  }

  function runRestore() {
    if (root.busy) return
    root.lastMessage = "Restoring… (configs snapshotted first)"
    restoreProc.command = [root.ctl, "restore", "--yes"]
    restoreProc.running = true
  }

  function saveRepo() {
    if (setRepoProc.running || root.repoDraft === "") return
    setRepoProc.command = [root.ctl, "set-repo", root.repoDraft]
    setRepoProc.running = true
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

        // --- repo --------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.showRepoEditor || !root.syncState.hasRepo

          Text {
            width: parent.width
            text: "Backup repo (GitHub URL or local path)"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
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
            enabled: root.repoDraft !== "" && !setRepoProc.running
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.saveRepo()
          }
        }

        // When a repo is set and editor hidden, show it compactly.
        Row {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo && !root.showRepoEditor

          Text {
            width: parent.width - editBtn.width - parent.spacing
            text: Model.shortRepo(root.syncState.repo)
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
          }

          Button {
            id: editBtn
            iconText: "󰏫"
            tooltipText: "Change repo"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: {
              root.repoDraft = root.syncState.repo
              root.showRepoEditor = true
            }
          }
        }

        // --- facts ---------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.spacing.xs
          visible: root.syncState.hasRepo

          Text {
            width: parent.width
            text: "Theme: " + (root.syncState.theme || "—") + "  ·  " + root.syncState.pluginCount + " plugin(s)"
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Text {
            width: parent.width
            visible: root.syncState.hasBackup
            text: "Last backup: " + root.syncState.lastBackup + (root.syncState.lastBackupHost ? " on " + root.syncState.lastBackupHost : "")
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        // --- actions ---------------------------------------------------
        Row {
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.syncState.hasRepo

          Button {
            text: root.busy ? "Working…" : "Back up now"
            enabled: !root.busy
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.runBackup()
          }

          Button {
            text: "Restore"
            tooltipText: "Restore configs + plugins from the repo (snapshots current state first)"
            enabled: !root.busy
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.runRestore()
          }
        }

        Text {
          width: parent.width
          visible: root.lastMessage !== ""
          text: root.lastMessage
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Fresh install? Install this plugin, then run:\nsettings-sync-ctl restore --repo <your-github-url> --yes"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
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
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastMessage = text.trim() === "" ? "Backup finished." : text.trim().split("\n").slice(-3).join("\n")
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text.trim() !== "") root.lastMessage = text.trim().split("\n").slice(-3).join("\n")
      }
    }
    onRunningChanged: if (!running) root.refresh()
  }

  Process {
    id: restoreProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.lastMessage = text.trim() === "" ? "Restore finished." : text.trim().split("\n").slice(-3).join("\n")
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text.trim() !== "") root.lastMessage = text.trim().split("\n").slice(-3).join("\n")
      }
    }
    onRunningChanged: if (!running) root.refresh()
  }

  Process {
    id: setRepoProc
    onRunningChanged: {
      if (running) return
      root.showRepoEditor = false
      root.refresh()
    }
  }
}
