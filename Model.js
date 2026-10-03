// Model.js — pure logic for the Settings Sync widget.
// Dual-environment: QML (`import "Model.js" as Model`) and node (require).

function defaultStatus() {
  return {
    repo: "",
    lastBackup: "",
    lastBackupHost: "",
    pluginCount: 0,
    theme: "",
    font: "",
    hasRepo: false,
    hasBackup: false,
    ghAuth: true
  };
}

function parseStatus(text) {
  var base = defaultStatus();
  if (!text || typeof text !== "string") return base;
  var trimmed = text.trim();
  if (trimmed === "") return base;
  try {
    var parsed = JSON.parse(trimmed);
    for (var k in base) {
      if (parsed && parsed[k] !== undefined && parsed[k] !== null) {
        base[k] = parsed[k];
      }
    }
    base.hasRepo = base.repo !== "";
    base.hasBackup = base.lastBackup !== "";
    return base;
  } catch (e) {
    return base;
  }
}

function shortRepo(repo) {
  if (!repo) return "no repo set";
  // https://github.com/user/omarchy-backup.git -> user/omarchy-backup
  var m = repo.match(/github\.com[:/](.+?)(\.git)?$/);
  if (m) return m[1];
  if (repo.length > 38) return "…" + repo.slice(-37);
  return repo;
}

function statusLine(state) {
  if (!state.hasRepo) return "Set a backup repo to begin";
  if (!state.hasBackup) return "Ready — no backup yet";
  return "Backed up " + state.lastBackup;
}

function tooltipText(state) {
  var lines = [];
  lines.push("Settings Sync");
  lines.push("Repo: " + (state.repo || "(none)"));
  if (state.hasBackup) {
    lines.push("Last backup: " + state.lastBackup);
    if (state.lastBackupHost) lines.push("Host: " + state.lastBackupHost);
  }
  if (state.theme) lines.push("Theme: " + state.theme);
  lines.push(state.pluginCount + " third-party plugin(s)");
  return lines.join("\n");
}

function glyphFor(state) {
  if (!state.hasRepo) return "󰒓";       // plug disconnected-ish
  if (!state.hasBackup) return "󰚓";      // cloud outline
  return "󰚒";                            // cloud check
}

function repoIsRemote(repo) {
  if (!repo) return false;
  return repo.indexOf("://") !== -1 || repo.indexOf("git@") === 0;
}

// Node exports for quick testing: `node -e "const M=require('./Model.js')..."`
try {
  if (typeof module !== "undefined" && module.exports) {
    module.exports = {
      defaultStatus: defaultStatus,
      parseStatus: parseStatus,
      shortRepo: shortRepo,
      statusLine: statusLine,
      tooltipText: tooltipText,
      glyphFor: glyphFor,
      repoIsRemote: repoIsRemote
    };
  }
} catch (e) { /* QML has no module — ignore */ }
