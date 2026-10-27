/* 荒野逐羊 · DM 工作台交互原型
   仅用于验证信息架构与关键流程，不是最终实现。 */

const ADVENTURE = {
  title: "荒野逐羊",
  original: "A Wild Sheep Chase",
  version: "0.2.0",
  level: "4–5 级",
  duration: "3–4 小时",
  warning: "变形 / 身体恐怖 · 动物伤害 · 囚禁与失去自主 · 暴力与死亡",
};

const FLAGS = [
  { id: "scroll-used", label: "卷轴已使用" },
  { id: "guz-defeated", label: "古兹被击败" },
  { id: "guz-captured", label: "古兹被俘" },
  { id: "shinebright-captured", label: "夏恩布莱特被俘" },
];

const SCENES = [
  {
    id: "scene-1",
    order: 1,
    title: "坏～～消息",
    subtitle: "绵羊冲进酒馆",
    duration: "20–30 分钟",
    summary:
      "队伍在午后被一头衔着卷轴的绵羊打断。它其实是法师夏恩布莱特，正被诺克的打手追赶。",
    readAloud:
      "一阵杂乱的蹄声、惊叫声和疯狂的咩咩声传来。你们还没来得及反应，一头白毛黑脸、卷角的绵羊便冲到面前，嘴里紧紧衔着一张精致的卷轴。",
    beats: [
      {
        id: "sheep-arrives",
        title: "绵羊冲进来",
        type: "event",
        text: "绵羊执意靠近队伍中魔法天赋最高的人，朝对方挥动卷轴。",
        readAloud: "它的眼神过于聪明，完全不像一头普通牲畜。",
        npc: "finethir-shinebright",
      },
      {
        id: "scroll-offered",
        title: "卷轴与蜡封",
        type: "decision",
        text: "蜡封标明这是“动物交谈卷轴（修改版）”。若有人大声读出，绵羊会热切地点头。",
        readAloud: "蜡封上刻着动物与舌头的符文；展开后，文字以精灵语写成。",
        spell: "speak-with-animals",
      },
      {
        id: "shinebright-intro",
        title: "绵羊开口",
        type: "roleplay",
        text: "使用卷轴后，咩叫变成有教养的精灵口音通用语。他自称范席尔·夏恩布莱特。",
        readAloud:
          "“谢天谢地，终于有人听得懂。我是范席尔·夏恩布莱特，变化系大师。现在，请先帮我弄回我的法杖。”",
        npc: "finethir-shinebright",
      },
      {
        id: "howling",
        title: "嚎叫",
        type: "transition",
        text: "他刚要讲自己的故事，空中响起嚎叫；古兹一伙正在靠近。",
        readAloud: "街角传来一声嚎叫，紧接着是沉重的脚步声和铁器碰撞声。",
        encounter: "guz-ambush",
      },
    ],
    branches: [
      {
        id: "if-scroll-used",
        label: "若队伍使用卷轴",
        requiresFlag: "scroll-used",
        text: "夏恩布莱特可以正常交谈，并请求队伍帮他夺回法杖；他愿意承诺报酬，但大多无法兑现。",
      },
      {
        id: "if-attack-sheep",
        label: "若队伍攻击绵羊",
        text: "绵羊惊慌逃窜，试图躲进人群；古兹会把这视为“诺克大人的财产受到威胁”，立即动手。",
      },
      {
        id: "if-ignore-sheep",
        label: "若队伍无视绵羊",
        text: "绵羊会一路尾随，直到古兹一伙找上门；它仍会试图把卷轴塞给施法者。",
      },
    ],
    encounterId: "guz-ambush",
    dmNotes: "绵羊不会主动攻击。若队伍完全无视它，古兹一伙仍会找上门。",
  },
  {
    id: "scene-2",
    order: 2,
    title: "牧羊人与骗子",
    subtitle: "古兹上门",
    duration: "45–60 分钟",
    summary:
      "古兹带着三头被变形的狼和一头棕熊上门索要“诺克大人的绵羊”。他不接受“不”这个答案。",
    readAloud:
      "一个巨大的半兽人推开人群，身后跟着三头眼神异常聪慧的狼，以及一个披着肮脏棕色斗篷、至少八英尺高的魁梧身影。“这头羊属于诺克大人。把它交出来。”",
    beats: [
      {
        id: "guz-arrives",
        title: "古兹上门",
        type: "encounter",
        text: "古兹要求交出绵羊；他身后的狼群会绕后抓人，棕熊负责堵路。",
        readAloud: "“把它交出来，我可以当你们没见过它。”",
        encounter: "guz-ambush",
      },
    ],
    branches: [
      {
        id: "if-guz-defeated",
        label: "若古兹被击败",
        requiresFlag: "guz-defeated",
        text: "夏恩布莱特恳求队伍送他回塔楼夺回法杖；他愿意承诺报酬，但需要被提醒才会兑现。",
      },
      {
        id: "if-guz-captured",
        label: "若古兹被俘",
        requiresFlag: "guz-captured",
        text: "队伍可以审问古兹，得知诺克仍在塔楼、守卫不多，以及“诺克大人最近越来越疯”。",
      },
      {
        id: "if-shinebright-captured",
        label: "若夏恩布莱特被俘",
        requiresFlag: "shinebright-captured",
        text: "古兹带着绵羊撤向诺克的树屋；队伍可以追击，或先处理当地当局。",
      },
    ],
    encounterId: "guz-ambush",
    dmNotes: "狼群要活捉夏恩布莱特，不杀死他；古兹则乐于把队伍打残。",
  },
];

const NPC = {
  id: "finethir-shinebright",
  name: "范席尔·夏恩布莱特",
  role: "被变成绵羊的法师 / 任务发布者",
  attitude: "friendly",
  public:
    "一头毛茸茸的白绵羊，黑脸、卷角，嘴里常衔着卷轴。它的眼神过于聪明，完全不像普通牲畜。",
  dm:
    "前高等精灵变化系法师，自恋、挑剔、书呆子气，但心地善良。两年前被学徒艾哈迈德·诺克用完全变形术变成绵羊，囚禁在自家花园里。他偷走动物交谈卷轴逃到镇上，急需队伍帮他夺回法杖。",
  voice: "有教养的精灵口音，语速快，容易跑题到自己的学术成就；变成绵羊后偶尔夹杂咩叫。",
  wants: ["拿回法杖", "恢复原形", "保住面子"],
  secrets: ["他承诺的报酬大多无法兑现", "他当年对诺克非常苛刻，把学徒当孩子使唤"],
  lines: [
    "“我是范席尔·夏恩布莱特，变化系大师。现在，请先帮我弄回我的法杖。”",
    "“多平面交织理论——这很难理解吗？”",
    "“咩——不，我是说，当然，报酬不成问题。”",
  ],
};

const MONSTERS = {
  guz: {
    name: "古兹",
    meta: "中型类人生物（半兽人），混乱中立",
    initMod: 1,
    ac: 14,
    hp: 67,
    speed: "30 尺",
    abilities: "STR 16 · DEX 12 · CON 17 · INT 8 · WIS 11 · CHA 8",
    traits: [
      ["鲁莽", "可以在自己回合内让所有近战武器攻击获得优势；直到下个回合开始前，针对他的攻击也获得优势。"],
      ["回旋巨剑", "近战武器攻击：命中 +5，触及 5 尺，两个目标。命中：10（2d6+3）挥砍伤害。"],
    ],
    tactics: ["冲前排，与棕熊并肩对付硬骨头。", "不聪明但忠诚；被话术绕晕时只会更愤怒。"],
  },
  wolf: {
    name: "被变形的狼",
    meta: "中型野兽（变形守卫），使用矮种马数据",
    initMod: 0,
    ac: 10,
    hp: 11,
    speed: "40 尺",
    abilities: "STR 15 · DEX 10 · CON 13 · INT 18 · WIS 14 · CHA 7",
    traits: [
      ["变形守卫", "保留人类心智；智力和感知分别为 18 和 14，会聪明地行动。"],
      ["啃咬", "近战武器攻击：命中 +4，触及 5 尺，一个目标。命中：7（2d4+2）钝击伤害。"],
    ],
    tactics: ["绕到队伍后方抓夏恩布莱特，优先活捉。"],
  },
  bear: {
    name: "棕熊",
    meta: "大型野兽，无阵营",
    initMod: 0,
    ac: 11,
    hp: 34,
    speed: "40 尺，攀爬 30 尺",
    abilities: "STR 19 · DEX 10 · CON 16 · INT 2 · WIS 13 · CHA 7",
    traits: [
      ["敏锐嗅觉", "依赖嗅觉的感知（察觉）检定具有优势。"],
      ["多重攻击", "发动一次啃咬和一次爪击。"],
      ["爪击", "近战武器攻击：命中 +5，触及 5 尺，一个目标。命中：11（2d6+4）挥砍伤害。"],
    ],
    tactics: ["守在古兹身侧，堵住通往队伍后排的路。"],
  },
};

const ENCOUNTER = {
  id: "guz-ambush",
  title: "古兹的伏击",
  summary: "古兹 + 3 头被变形的狼 + 1 头棕熊",
  monsters: ["古兹", "被变形的狼 ×3", "棕熊"],
  tactics: [
    "古兹冲前排，与棕熊并肩对付硬骨头。",
    "狼群绕后抓夏恩布莱特；它们要活捉，不杀死。",
    "若战局不利，古兹可能谈条件或撤退。",
  ],
};

const MAP = {
  title: "诺克的树屋宅院",
  image: "assets/map.jpg",
  pins: [
    { id: "central-platform", label: "中央平台（主宅）", x: 0.57, y: 0.25, dmOnly: false, description: "图书馆/实验室、起居室、餐厅兼厨房；诺克通常在这里研究法术。" },
    { id: "garden-platform", label: "花园平台", x: 0.78, y: 0.6, dmOnly: false, description: "修剪整齐的草坪与石径；最低的平台，离地约 10 尺。" },
    { id: "bedroom-platform", label: "卧室平台", x: 0.43, y: 0.56, dmOnly: true, description: "最高的平台，诺克的卧室；法杖通常随身，房里有衣柜、大床和梳妆台。" },
    { id: "west-hut", label: "西侧小屋", x: 0.23, y: 0.69, dmOnly: true, description: "平台下的小屋，守卫休息处；床铺偏大。" },
    { id: "outhouse", label: "外屋 / 小屋", x: 0.55, y: 0.71, dmOnly: true, description: "户外厕所；战斗开始时棕熊正在里面“办事”。" },
    { id: "bridge", label: "花园桥", x: 0.69, y: 0.87, dmOnly: false, description: "说出通行口令 Mae Tref Cathode 后，枝条会连接花园平台与中央平台。" },
    { id: "entry-slope", label: "入口坡道", x: 0.72, y: 0.96, dmOnly: false, description: "由树根和枝条形成的缓坡，连接主路与花园平台。" },
  ],
};

const RULES = [
  {
    id: "concentration",
    term: "专注",
    category: "核心规则",
    summary:
      "同一时间只能专注一个法术。受伤时进行体质豁免，DC 为 10 或伤害一半（取较高者）；失败则法术结束。",
  },
  {
    id: "speak-with-animals",
    term: "动物交谈",
    category: "法术 · 1 环 · 仪式",
    summary:
      "你获得理解并口头回应动物的能力；无法说服动物做超出其理解或能力范围的事。这张卷轴版本持续八小时。",
  },
];

const PARTY_A = [
  { id: "pc-1", name: "阿岚", role: "战士", level: 4, ac: 18, hp: 36, maxHp: 44, initMod: 1, pp: 12, conditions: [] },
  { id: "pc-2", name: "米娅", role: "法师", level: 4, ac: 13, hp: 22, maxHp: 27, initMod: 3, pp: 11, conditions: [] },
  { id: "pc-3", name: "老科", role: "牧师", level: 4, ac: 17, hp: 31, maxHp: 38, initMod: 0, pp: 15, conditions: [] },
  { id: "pc-4", name: "小影", role: "游荡者", level: 4, ac: 15, hp: 26, maxHp: 33, initMod: 4, pp: 16, conditions: [] },
];

const PARTY_B = [
  { id: "pc-b1", name: "森", role: "圣武士", level: 4, ac: 18, hp: 40, maxHp: 40, initMod: 0, pp: 11, conditions: [] },
  { id: "pc-b2", name: "鹿鸣", role: "德鲁伊", level: 4, ac: 14, hp: 28, maxHp: 28, initMod: 2, pp: 15, conditions: [] },
  { id: "pc-b3", name: "卡莉", role: "吟游诗人", level: 4, ac: 14, hp: 24, maxHp: 24, initMod: 3, pp: 10, conditions: [] },
];

function initialRuns() {
  return {
    "fri-a": {
      id: "fri-a",
      name: "周五团 · A 组",
      lastPlayed: "今天 20:14",
      status: "active",
      statusLabel: "进行中",
      sceneId: "scene-2",
      beatId: "guz-arrives",
      mode: "scene",
      party: PARTY_A,
      flags: { "scroll-used": true },
      combat: null,
      combatDraft: null,
      stickyNotes: [
        { id: "note-a1", text: "上次停在古兹上门；队伍还没决定是否动手。", color: "yellow", createdAt: Date.now() - 1000 * 60 * 60 * 20, updatedAt: Date.now() - 1000 * 60 * 60 * 20 },
        { id: "note-a2", text: "如果玩家抓住古兹，可以让他说出塔楼口令。", color: "blue", createdAt: Date.now() - 1000 * 60 * 60 * 3, updatedAt: Date.now() - 1000 * 60 * 60 * 3 },
      ],
      sessions: 2,
    },
    "sun-new": {
      id: "sun-new",
      name: "周日新手团",
      lastPlayed: "10 月 24 日",
      status: "waiting",
      statusLabel: "待开团",
      sceneId: "scene-1",
      beatId: "sheep-arrives",
      mode: "scene",
      party: PARTY_B,
      flags: {},
      combat: null,
      combatDraft: null,
      stickyNotes: [
        { id: "note-b1", text: "开场前过安全工具；确认玩家都带了 4 级角色。", color: "pink", createdAt: Date.now() - 1000 * 60 * 60 * 48, updatedAt: Date.now() - 1000 * 60 * 60 * 48 },
      ],
      sessions: 0,
    },
    "solo-test": {
      id: "solo-test",
      name: "单刷测试团",
      lastPlayed: "10 月 18 日",
      status: "done",
      statusLabel: "已完成",
      sceneId: "scene-1",
      beatId: "howling",
      mode: "scene",
      party: [{ id: "pc-s1", name: "测试", role: "战士", level: 4, ac: 18, hp: 30, maxHp: 44, initMod: 1, pp: 10, conditions: [] }],
      flags: { "scroll-used": true },
      combat: null,
      combatDraft: null,
      stickyNotes: [
        { id: "note-s1", text: "用来验证旧版流程的存档。", color: "green", createdAt: Date.now() - 1000 * 60 * 60 * 72, updatedAt: Date.now() - 1000 * 60 * 60 * 72 },
      ],
      sessions: 3,
    },
  };
}

let runs = initialRuns();
let state = {
  screen: "library",
  activeRunId: "fri-a",
  inspector: "party",
  modal: null,
  privacy: false,
  selectedPinId: null,
  showSecrets: false,
  saveLabel: "已保存",
  pending: null,
  newRunName: "",
  resetScroll: false,
};
let saveTimer = null;
let toastTimer = null;
let draftSeq = 0;
let stickySeq = 0;
let partySeq = 0;

/* ---------- helpers ---------- */

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function getRun() {
  return runs[state.activeRunId];
}

function sceneById(id) {
  return SCENES.find((scene) => scene.id === id) || SCENES[0];
}

function beatById(scene, id) {
  return scene.beats.find((beat) => beat.id === id) || scene.beats[0];
}

function flagLabel(id) {
  return FLAGS.find((flag) => flag.id === id)?.label || id;
}

function hpClass(current, max) {
  const ratio = max > 0 ? current / max : 0;
  if (ratio <= 0.25) return "crit";
  if (ratio <= 0.5) return "low";
  return "";
}

function avatar(name, extraClass = "") {
  return `<span class="avatar ${extraClass}">${escapeHtml(name.slice(0, 1))}</span>`;
}

function activeCombatant(run) {
  if (!run.combat) return null;
  return run.combat.combatants.find((item) => item.id === run.combat.activeId) || null;
}

function monsterFor(combatant) {
  if (!combatant) return null;
  return MONSTERS[combatant.baseId || combatant.id] || null;
}

function syncParty(run) {
  if (!run.combat) return;
  run.party.forEach((member) => {
    const combatant = run.combat.combatants.find((item) => item.id === member.id);
    if (combatant) {
      member.hp = combatant.hp;
      member.conditions = [...combatant.conditions];
    }
  });
}

function rollD20(modifier = 0) {
  return 1 + Math.floor(Math.random() * 20) + modifier;
}

function ensureDraft(run) {
  if (!run.combatDraft) {
    run.combatDraft = { players: [], monsters: [], initiative: {}, stage: "select" };
  }
  return run.combatDraft;
}

function draftPlayers(run) {
  const draft = ensureDraft(run);
  return draft.players.map((id) => run.party.find((member) => member.id === id)).filter(Boolean);
}

function suggestedEncounter(run) {
  const players = draftPlayers(run);
  if (players.length === 0) {
    return {
      title: "先选择参战玩家",
      detail: "怪物建议会根据参战人数和平均等级变化；不会自动加入。",
    };
  }
  const avgLevel = players.reduce((sum, member) => sum + (member.level || 4), 0) / players.length;
  let wolves = Math.max(1, players.length - 1);
  if (avgLevel >= 5) wolves += 1;
  const bear = players.length >= 4 ? 1 : 0;
  return {
    title: `古兹 ×1 · 狼 ×${wolves} · 棕熊 ×${bear}`,
    detail: `${players.length} 人 · 平均 ${avgLevel.toFixed(1)} 级。原型建议，按实际队伍调整。`,
  };
}

function addDraftMonster(baseId, run = getRun()) {
  const draft = ensureDraft(run);
  const count = draft.monsters.filter((monster) => monster.baseId === baseId).length + 1;
  const baseName = MONSTERS[baseId].name;
  const name =
    baseId === "wolf" ? `狼 ${count}` :
    baseId === "bear" ? (count === 1 ? "棕熊" : `棕熊 ${count}`) :
    (count === 1 ? "古兹" : `古兹 ${count}`);
  draft.monsters.push({
    id: `draft-${baseId}-${++draftSeq}`,
    baseId,
    name,
  });
}

function toggleDraftPlayer(playerId) {
  const run = getRun();
  const draft = ensureDraft(run);
  if (draft.players.includes(playerId)) {
    draft.players = draft.players.filter((id) => id !== playerId);
    delete draft.initiative[playerId];
  } else {
    draft.players.push(playerId);
  }
  render();
  flashSave();
}

function clearDraft() {
  const run = getRun();
  run.combatDraft = { players: [], monsters: [], initiative: {}, stage: "select" };
  render();
  flashSave();
}

function initiativeReady(run) {
  const draft = ensureDraft(run);
  if (draft.players.length + draft.monsters.length === 0) return false;
  return draft.players.every((id) => {
    const value = draft.initiative[id];
    return value !== undefined && value !== "" && Number.isFinite(Number(value));
  }) && draft.monsters.every((monster) => {
    const value = draft.initiative[monster.id];
    return value !== undefined && value !== "" && Number.isFinite(Number(value));
  });
}

function goInitiativeStage() {
  const run = getRun();
  const draft = ensureDraft(run);
  if (draft.players.length + draft.monsters.length === 0) {
    showToast("先选择参战玩家，或添加至少一个怪物");
    return;
  }
  draft.monsters.forEach((monster) => {
    const current = draft.initiative[monster.id];
    if (current === undefined || current === "") {
      draft.initiative[monster.id] = String(rollD20(MONSTERS[monster.baseId].initMod || 0));
    }
  });
  draft.stage = "initiative";
  render();
  flashSave();
}

function backToSelect() {
  const run = getRun();
  ensureDraft(run).stage = "select";
  render();
  flashSave();
}

function updateInitiativeReady() {
  const run = getRun();
  const rows = initiativeRows(run);
  const ready = initiativeReady(run);
  const filled = rows.filter((row) => row.value !== "").length;

  document.querySelectorAll("[data-init-progress]").forEach((node) => {
    node.textContent = `${filled}/${rows.length}`;
  });
  document.querySelectorAll("[data-init-mini]").forEach((node) => {
    const row = rows.find((item) => item.id === node.dataset.initMini);
    if (!row) return;
    node.classList.toggle("filled", row.value !== "");
    const valueNode = node.querySelector("[data-init-mini-value]");
    if (valueNode) valueNode.textContent = row.value !== "" ? String(row.value) : "—";
  });
  document.querySelectorAll('[data-action="begin-combat"]').forEach((button) => {
    button.disabled = !ready;
  });
}

function startCombatFromDraft({ silent = false } = {}) {
  const run = getRun();
  const draft = ensureDraft(run);
  const players = draftPlayers(run);
  const monsters = draft.monsters;
  const total = players.length + monsters.length;

  if (total === 0) {
    if (!silent) showToast("先选择参战玩家，或添加至少一个怪物");
    return;
  }
  if (!initiativeReady(run)) {
    if (!silent) showToast("先把所有参战者的先攻填完");
    return;
  }

  const combatants = [];
  players.forEach((member) => {
    combatants.push({
      ...member,
      kind: "pc",
      conditions: [...member.conditions],
      initiative: Number(draft.initiative[member.id]),
    });
  });
  monsters.forEach((monster) => {
    const stat = MONSTERS[monster.baseId];
    combatants.push({
      ...monster,
      kind: "monster",
      ac: stat.ac,
      hp: stat.hp,
      maxHp: stat.hp,
      role: stat.meta,
      conditions: [],
      initiative: Number(draft.initiative[monster.id]),
    });
  });

  combatants.sort((a, b) => b.initiative - a.initiative || a.name.localeCompare(b.name, "zh-CN"));
  run.combat = {
    round: 1,
    activeId: combatants[0]?.id || null,
    combatants,
    log: [
      `先攻记录 → ${combatants.map((item) => `${item.name} ${item.initiative}`).join(" · ")}`,
      `第 1 轮 · ${combatants[0]?.name || "—"} 的回合`,
    ],
  };
  run.combatDraft = null;
  run.mode = "combat";
  state.inspector = "battle";

  if (!silent) {
    render();
    flashSave();
    showToast("先攻已记录，进入第 1 轮");
  }
}

function openCombatSetup() {
  const run = getRun();
  ensureDraft(run);
  run.mode = "combat";
  state.inspector = "battle";
  render();
  flashSave();
  showToast(run.combatDraft.stage === "initiative" ? "填写参战者的先攻，然后开始战斗" : "选择参战玩家和怪物，然后填写先攻");
}

function ensureDemoCombat(run) {
  ensureDraft(run);
  const draft = run.combatDraft;
  draft.players = run.party.map((member) => member.id);
  draft.monsters = [];
  ["guz", "wolf", "wolf", "wolf", "bear"].forEach((baseId) => addDraftMonster(baseId, run));
  draft.stage = "initiative";
  draft.initiative = {};
  run.party.forEach((member) => {
    draft.initiative[member.id] = String(rollD20(member.initMod || 0));
  });
  draft.monsters.forEach((monster) => {
    draft.initiative[monster.id] = String(rollD20(MONSTERS[monster.baseId].initMod || 0));
  });
  startCombatFromDraft({ silent: true });
}

function flashSave() {
  state.saveLabel = "保存中…";
  const el = document.getElementById("save-status");
  if (el) el.innerHTML = `<span class="save-dot saving"></span>保存中…`;
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    state.saveLabel = "已保存 · 刚刚";
    const node = document.getElementById("save-status");
    if (node) node.innerHTML = `<span class="save-dot"></span>已保存 · 刚刚`;
  }, 420);
}

function showToast(message) {
  const toast = document.getElementById("toast");
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 2300);
}

/* ---------- render ---------- */

function render() {
  const app = document.getElementById("app");
  const run = getRun();
  const center = document.querySelector(".center");
  const scrollTop = center ? center.scrollTop : 0;

  app.innerHTML = `
    ${titlebar(run)}
    ${state.screen === "library" ? libraryView() : workspaceView(run)}
    ${statusbar(run)}
  `;

  renderOverlays();

  requestAnimationFrame(() => {
    const nextCenter = document.querySelector(".center");
    if (nextCenter) nextCenter.scrollTop = state.resetScroll ? 0 : scrollTop;
    state.resetScroll = false;
  });
}

function titlebar(run) {
  const scene = state.screen === "run" ? sceneById(run.sceneId) : null;
  return `
    <header class="titlebar">
      <div class="traffic" aria-hidden="true"><span></span><span></span><span></span></div>
      <div class="brand">荒野逐羊 <small>DM 工作台</small></div>
      ${state.screen === "run" ? `<div class="crumbs"><b>${escapeHtml(run.name)}</b><span class="sep">/</span>${escapeHtml(scene.title)}</div>` : ""}
      <div class="toolbar">
        <span class="proto-badge">PROTOTYPE</span>
        ${
          state.screen === "run"
            ? `<div class="segmented" role="group" aria-label="视图">
                 ${modeButton("scene", "▤ 场景", run)}
                 ${modeButton("combat", "◇ 战斗", run)}
                 ${modeButton("map", "⌖ 地图", run)}
               </div>`
            : ""
        }
        <button class="btn ghost small" data-action="privacy" title="临时遮挡 DM 内容">◐ 遮屏</button>
        ${
          state.screen === "run"
            ? `<button class="btn ghost small" data-action="library">◫ 我的开团</button>`
            : ""
        }
      </div>
    </header>
  `;
}

function modeButton(mode, label, run) {
  return `<button class="seg-btn ${run.mode === mode ? "active" : ""}" data-action="mode" data-mode="${mode}">${label}</button>`;
}

function libraryView() {
  const runList = Object.values(runs);
  return `
    <section class="library fade-in">
      <div class="library-head">
        <div>
          <p class="eyebrow">DM 工作台 / 我的开团</p>
          <h1 class="display">我的开团</h1>
          <p class="lede">一份内容包，多次独立记录。每次开团有自己的队伍、进度、战斗状态和笔记。</p>
        </div>
        <button class="btn primary" data-action="new-run">＋ 新建开团</button>
      </div>

      <div class="warning-strip"><b>内容提示</b><span>${escapeHtml(ADVENTURE.warning)}</span></div>

      <div class="run-grid">
        ${runList.map((run) => runCard(run)).join("")}
      </div>

      <div class="library-lower">
        <div class="pack-card">
          <img class="pack-cover" src="assets/cover.jpg" alt="">
          <div class="pack-body">
            <p class="eyebrow">内容包</p>
            <h3>${escapeHtml(ADVENTURE.title)}</h3>
            <p>${escapeHtml(ADVENTURE.original)} · ${escapeHtml(ADVENTURE.level)} · ${escapeHtml(ADVENTURE.duration)} · 3–5 人</p>
            <div class="chip-row">
              <span class="tag green">2 场景已接入</span>
              <span class="tag">1 张地图</span>
              <span class="tag">2 张规则卡</span>
            </div>
            <p style="margin-top:7px">本地内容包 v${escapeHtml(ADVENTURE.version)} · 个人使用</p>
          </div>
        </div>
        <div class="progress-card">
          <div class="pack-body">
            <p class="eyebrow">Schema spike</p>
            <h3>本轮已接入</h3>
            <ul class="check-list">
              <li class="on">场景 1 · 坏～～消息</li>
              <li class="on">场景 2 · 牧羊人与骗子</li>
              <li class="on">古兹遭遇 + 3 怪物</li>
              <li class="on">树屋地图 + 图钉</li>
              <li class="todo">场景 3–4</li>
              <li class="todo">诺克 / 床龙雏龙</li>
            </ul>
          </div>
        </div>
      </div>

      <div class="prep-strip">
        <div class="prep-head"><p class="eyebrow">开团前</p><h3>三件事</h3></div>
        <div class="prep-grid">
          <div class="prep-item"><span>01</span><p>过一遍场景 1–2 的朗读与节拍</p></div>
          <div class="prep-item"><span>02</span><p>确认内容提示与桌面安全备注</p></div>
          <div class="prep-item"><span>03</span><p>填好队伍 AC / HP / 先攻 / 被动感知</p></div>
        </div>
      </div>

      <img class="library-sheep" src="assets/sheep-ink.png" alt="">

      <div class="library-foot">
        <span>内容包 v${escapeHtml(ADVENTURE.version)} · ${SCENES.length} 个场景已接入 · 本地存储</span>
        <button class="link-btn" data-action="reset-demo">重置演示数据</button>
      </div>
    </section>
  `;
}

function runCard(run) {
  const currentIndex = SCENES.findIndex((scene) => scene.id === run.sceneId);
  const statusClass = run.status === "active" ? "active" : run.status === "waiting" ? "waiting" : "done";
  return `
    <article class="run-card ${run.id === state.activeRunId ? "current" : ""}" data-action="open-run" data-run="${run.id}" tabindex="0" role="button">
      <div class="run-card-head">
        <img class="run-cover" src="assets/cover.jpg" alt="">
        <div class="run-title">
          <p class="run-name">${escapeHtml(run.name)}</p>
          <div class="run-sub">${escapeHtml(ADVENTURE.title)} · ${run.sessions > 0 ? `已进行 ${run.sessions} 次` : "尚未开始"}</div>
        </div>
        <span class="pill ${statusClass}">${escapeHtml(run.statusLabel)}</span>
      </div>
      <div class="progress-line">
        <div class="progress-track">
          ${SCENES.map((scene, index) => `<span class="progress-seg ${index <= currentIndex ? "on" : ""} ${index === currentIndex ? "current" : ""}"></span>`).join("")}
        </div>
        <span class="progress-text">场景 ${currentIndex + 1} / ${SCENES.length}</span>
      </div>
      <div class="run-meta">
        <span>上次游玩 · ${escapeHtml(run.lastPlayed)}</span>
        <span class="avatar-stack">
          ${run.party.slice(0, 4).map((member) => avatar(member.name, "sm")).join("")}
          ${run.party.length === 0 ? `<span class="run-sub">空白队伍</span>` : ""}
        </span>
      </div>
      <div class="run-card-foot">
        <span>${run.party.length} 人队伍 · ${run.party.length ? "最小战斗面板" : "手动录入"}</span>
        <span class="go">继续带团 →</span>
      </div>
    </article>
  `;
}

function workspaceView(run) {
  return `
    <div class="workspace">
      <aside class="rail">${rail(run)}</aside>
      <main class="center"><div class="content-scroll">${centerView(run)}</div></main>
      <aside class="inspector">${inspector(run)}</aside>
    </div>
  `;
}

function rail(run) {
  const scene = sceneById(run.sceneId);
  return `
    <div class="rail-head">
      <p class="eyebrow">当前开团</p>
      <h2>${escapeHtml(run.name)}</h2>
      <p>${escapeHtml(ADVENTURE.title)} · ${escapeHtml(ADVENTURE.level)} · 场景 ${scene.order}/${SCENES.length}</p>
    </div>

    <div class="rail-section">
      <div class="rail-label">场景轨道 <span>${SCENES.length} 场</span></div>
      ${SCENES.map((item) => `
        <button class="scene-item ${item.id === scene.id ? "active" : ""}" data-action="select-scene" data-scene="${item.id}">
          <span class="scene-num">${item.order}</span>
          <span class="scene-text"><b>${escapeHtml(item.title)}</b><small>${escapeHtml(item.subtitle)}</small></span>
        </button>
      `).join("")}
    </div>

    <div class="rail-section">
      <div class="rail-label">节拍 <span>${scene.beats.length} 拍</span></div>
      <div class="beat-rail">
        ${scene.beats.map((beat) => `
          <button class="beat-rail-item ${beat.id === run.beatId ? "active" : ""}" data-action="select-beat" data-beat="${beat.id}">${escapeHtml(beat.title)}</button>
        `).join("")}
      </div>
    </div>

    <div class="rail-bottom">
      <button class="btn ghost" data-action="library">◫ 切换开团</button>
    </div>
  `;
}

function centerView(run) {
  if (run.mode === "combat") return combatView(run);
  if (run.mode === "map") return mapView(run);
  return sceneView(run);
}

const BEAT_TYPE = {
  event: "事件",
  decision: "决策",
  roleplay: "扮演",
  encounter: "遭遇",
  transition: "转场",
  note: "备注",
};

function sceneView(run) {
  const scene = sceneById(run.sceneId);
  const activeBeat = beatById(scene, run.beatId);
  return `
    <section class="fade-in">
      <div class="scene-head">
        <div class="scene-kicker">
          <span class="tag red">场景 ${String(scene.order).padStart(2, "0")} / ${String(SCENES.length).padStart(2, "0")}</span>
          <span class="tag">约 ${escapeHtml(scene.duration)}</span>
          <span class="tag amber">当前拍 · ${escapeHtml(activeBeat.title)}</span>
        </div>
        <h1>${escapeHtml(scene.title)}</h1>
        <p class="lede">${escapeHtml(scene.summary)}</p>
        <div class="chip-row">
          <span class="tag">${escapeHtml(ADVENTURE.level)}</span>
          <span class="tag">3–5 人</span>
          <span class="tag green">内容包 v${escapeHtml(ADVENTURE.version)}</span>
        </div>
      </div>

      ${scene.readAloud ? `<blockquote class="read-aloud"><span class="label">朗读 / 描述</span><p>${escapeHtml(scene.readAloud)}</p></blockquote>` : ""}

      <div class="section-head"><h2>节拍</h2><span>${scene.beats.length} 个 · 点击切换当前拍</span></div>
      <div class="beat-stack">
        ${scene.beats.map((beat, index) => beatCard(beat, index, run)).join("")}
      </div>

      ${scene.encounterId ? `
        <div class="encounter-card">
          <div>
            <p class="eyebrow">遭遇</p>
            <h3>${escapeHtml(ENCOUNTER.title)}</h3>
            <p>参考组合：${escapeHtml(ENCOUNTER.summary)}；按队伍人数与等级调整。</p>
            <div class="encounter-monsters">${ENCOUNTER.monsters.map((monster) => `<span class="tag amber">${escapeHtml(monster)}</span>`).join("")}</div>
          </div>
          <button class="btn primary" data-action="${run.combat ? "mode" : "open-combat"}" ${run.combat ? 'data-mode="combat"' : ""}>◇ ${run.combat ? "返回战斗" : "筹备战斗"}</button>
        </div>
      ` : ""}


      <div class="section-head"><h2>如果玩家……</h2><span>手动 flag · App 只提示</span></div>
      <div class="branch-grid">
        ${scene.branches.map((branch) => {
          const triggered = branch.requiresFlag ? Boolean(run.flags[branch.requiresFlag]) : false;
          return `
            <div class="branch-card ${triggered ? "triggered" : ""}">
              <span class="label">${escapeHtml(branch.label)}</span>
              <p>${escapeHtml(branch.text)}</p>
              ${branch.requiresFlag ? `<span class="branch-flag">${triggered ? "● 已触发" : "○ 条件"}：${escapeHtml(flagLabel(branch.requiresFlag))}</span>` : ""}
            </div>
          `;
        }).join("")}
      </div>

      <div class="flag-card">
        <div class="flag-head"><h3>本团状态</h3><span>只影响提示，不自动改剧情</span></div>
        <div class="flag-row">
          ${FLAGS.map((flag) => `<button class="flag-toggle ${run.flags[flag.id] ? "on" : ""}" data-action="toggle-flag" data-flag="${flag.id}">${escapeHtml(flag.label)}</button>`).join("")}
        </div>
      </div>

      <div class="dm-note"><b>DM 备注：</b>${escapeHtml(scene.dmNotes)}</div>
    </section>
  `;
}

function beatCard(beat, index, run) {
  const active = beat.id === run.beatId;
  return `
    <div class="beat-card ${active ? "active" : ""}" data-action="select-beat" data-beat="${beat.id}" role="button" tabindex="0">
      <div class="beat-index">${String(index + 1).padStart(2, "0")}</div>
      <div class="beat-content">
        <div class="beat-meta">
          <span class="tag ${beat.type === "encounter" ? "red" : beat.type === "decision" ? "amber" : "blue"}">${BEAT_TYPE[beat.type] || beat.type}</span>
          ${beat.npc ? `<button class="tag red" data-action="open-npc" data-npc="${beat.npc}">◈ ${escapeHtml(NPC.name)}</button>` : ""}
          ${beat.spell ? `<span class="tag">法术卡</span>` : ""}
          ${beat.encounter ? `<span class="tag">遭遇</span>` : ""}
        </div>
        <h3>${escapeHtml(beat.title)}</h3>
        <p>${escapeHtml(beat.text)}</p>
        ${beat.readAloud ? `<p class="beat-read">“${escapeHtml(beat.readAloud)}”</p>` : ""}
      </div>
    </div>
  `;
}

function inspector(run) {
  const tabs = [
    ["party", "队伍"],
    ["battle", "战斗"],
    ["rules", "速查"],
    ["notes", "笔记"],
  ];
  return `
    <div class="inspector-tabs">
      ${tabs.map(([id, label]) => `<button class="tab ${state.inspector === id ? "active" : ""}" data-action="tab" data-tab="${id}">${label}</button>`).join("")}
    </div>
    <div class="inspector-body">
      ${state.inspector === "party" ? partyPanel(run) : ""}
      ${state.inspector === "battle" ? battlePanel(run) : ""}
      ${state.inspector === "rules" ? rulesPanel() : ""}
      ${state.inspector === "notes" ? notesPanel(run) : ""}
    </div>
  `;
}

function partyPanel(run) {
  return `
    <div class="panel-head"><h2>队伍</h2><span>${run.party.length} 人 · 最小面板</span></div>
    <button class="btn primary" style="width:100%;margin-bottom:8px" data-action="new-party-member">＋ 添加玩家</button>
    ${
      run.party.length === 0
        ? `<div class="empty">这个开团还没有录入队伍。<br>新建开团时选择了“完全空白”，在这里手动添加。</div>`
        : `<div class="party-list">${run.party.map((member) => partyRow(member)).join("")}</div>`
    }
    <div class="note-hint">只需要姓名、等级、AC、HP、先攻加值和被动感知；不管理角色卡、升级或法术位。</div>
  `;
}

function partyRow(member) {
  const pct = Math.max(0, Math.min(100, (member.hp / member.maxHp) * 100));
  return `
    <div class="party-row">
      <div class="party-top">
        ${avatar(member.name, "sm")}
        <div class="party-name"><b>${escapeHtml(member.name)}</b><small>Lv ${member.level} · ${escapeHtml(member.role)} · AC ${member.ac} · 被动 ${member.pp}</small></div>
        <div class="party-stats">${member.hp}/${member.maxHp}</div>
      </div>
      <div class="hp-line">
        <div class="hp-bar"><div class="hp-fill ${hpClass(member.hp, member.maxHp)}" style="width:${pct}%"></div></div>
      </div>
      ${member.conditions?.length ? `<div class="conditions">${member.conditions.map((condition) => `<span class="condition-pill">${escapeHtml(condition)}</span>`).join("")}</div>` : ""}
    </div>
  `;
}

function battlePanel(run) {
  return run.combat ? battleTracker(run) : battleSetupPanel(run);
}

function initiativeRows(run) {
  const draft = ensureDraft(run);
  const rows = [];
  draft.players.forEach((id) => {
    const member = run.party.find((item) => item.id === id);
    if (member) {
      rows.push({
        id,
        name: member.name,
        kindLabel: "玩家",
        note: "玩家自己掷，DM 填写",
        editable: true,
        modifier: member.initMod || 0,
        value: draft.initiative[id] ?? "",
      });
    }
  });
  draft.monsters.forEach((monster) => {
    rows.push({
      id: monster.id,
      name: monster.name,
      kindLabel: "怪物",
      note: "自动 d20 + 先攻加值",
      editable: false,
      modifier: MONSTERS[monster.baseId].initMod || 0,
      value: draft.initiative[monster.id] ?? "",
    });
  });
  return rows;
}

function battleSetupPanel(run) {
  const draft = ensureDraft(run);
  const players = draftPlayers(run);
  const total = players.length + draft.monsters.length;
  const rows = initiativeRows(run);
  const filled = rows.filter((row) => row.value !== "").length;

  if (draft.stage === "initiative") {
    return `
      <div class="panel-head"><h2>战斗</h2><span>填写先攻</span></div>
      <div class="setup-hint">玩家自己掷，你只需填结果；怪物先攻已自动掷好（d20 + 加值）。</div>
      <div class="setup-progress"><b data-init-progress>${filled}/${total}</b><span>已填写</span></div>
      <div class="init-mini-list">
        ${rows.map((row) => `
          <div class="init-mini-row ${row.value !== "" ? "filled" : ""}" data-init-mini="${row.id}">
            <span>${escapeHtml(row.name)}</span>
            <small>${row.kindLabel}</small>
            <b data-init-mini-value>${row.value !== "" ? escapeHtml(String(row.value)) : "—"}</b>
          </div>
        `).join("")}
      </div>
      <button class="btn primary" style="width:100%;margin-top:10px" data-action="begin-combat" ${initiativeReady(run) ? "" : "disabled"}>开始战斗 →</button>
      <button class="btn ghost" style="width:100%;margin-top:6px" data-action="back-to-select">返回选择参战者</button>
    `;
  }

  return `
    <div class="panel-head"><h2>战斗</h2><span>${total} 个参战者</span></div>
    <div class="setup-hint">在中间逐个选择玩家、添加怪物；准备好后填写先攻。</div>
    <div class="setup-count-grid">
      <div><b>${players.length}</b><span>参战玩家</span></div>
      <div><b>${draft.monsters.length}</b><span>参战怪物</span></div>
    </div>
    <div class="suggest-card">
      <span>建议组合</span>
      <b>${escapeHtml(suggestedEncounter(run).title)}</b>
      <small>${escapeHtml(suggestedEncounter(run).detail)}</small>
    </div>
    <button class="btn primary" style="width:100%" data-action="next-initiative" ${total === 0 ? "disabled" : ""}>下一步：填写先攻 →</button>
    <button class="btn ghost" style="width:100%;margin-top:6px" data-action="clear-draft" ${total === 0 ? "disabled" : ""}>清空参战者</button>
  `;
}

function battleTracker(run) {
  return `
    <div class="panel-head"><h2>战斗</h2><span>第 ${run.combat.round} 轮 · ${run.combat.combatants.length} 个战斗者</span></div>
    <div class="round-bar"><b>第 ${run.combat.round} 轮</b><span>当前：${escapeHtml(activeCombatant(run)?.name || "—")}</span></div>
    <div class="init-list">
      ${run.combat.combatants.map((item) => `
        <button class="init-row ${item.id === run.combat.activeId ? "active" : ""}" data-action="select-combatant" data-combatant="${item.id}">
          <span class="init-num">${item.initiative}</span>
          <span class="init-name"><b>${escapeHtml(item.name)}</b><small>${item.kind === "pc" ? "玩家" : "怪物"} · AC ${item.ac}</small></span>
          <span class="init-hp">${item.hp}/${item.maxHp}</span>
        </button>
      `).join("")}
    </div>
    <div class="dice-row">
      <button class="btn" data-action="roll-dice" data-mode="d20">d20</button>
      <button class="btn" data-action="roll-dice" data-mode="adv">优势</button>
      <button class="btn" data-action="roll-dice" data-mode="dis">劣势</button>
    </div>
    <button class="btn primary" style="width:100%" data-action="next-turn">下一回合 →</button>
    <button class="btn ghost" style="width:100%;margin-top:6px" data-action="end-combat">结束战斗</button>
  `;
}

function setupSteps(active) {
  const steps = [
    ["select", "01", "选择参战者", "玩家 + 怪物"],
    ["initiative", "02", "填写先攻", "玩家填 · 怪物自动"],
    ["combat", "03", "按轮次战斗", "下一回合"],
  ];
  return `
    <div class="setup-steps">
      ${steps.map(([id, number, title, hint]) => `
        <div class="setup-step ${active === id ? "active" : ""}">
          <span>${number}</span><b>${title}</b><small>${hint}</small>
        </div>
      `).join("")}
    </div>
  `;
}

function combatSetupView(run) {
  const draft = ensureDraft(run);
  return draft.stage === "initiative" ? initiativeEntryView(run) : selectionSetupView(run);
}

function selectionSetupView(run) {
  const draft = ensureDraft(run);
  const players = draftPlayers(run);
  const total = players.length + draft.monsters.length;
  const suggestion = suggestedEncounter(run);

  return `
    <section class="fade-in">
      <div class="combat-head">
        <div>
          <p class="eyebrow">战斗筹备</p>
          <h1>先选人，再填先攻</h1>
          <p class="lede">不是所有玩家都会参战，怪物数量也会随人数和等级变化。这里只给建议，不会自动加入。</p>
        </div>
        <div class="combat-actions">
          <button class="btn primary" data-action="next-initiative" ${total === 0 ? "disabled" : ""}>下一步：填写先攻 →</button>
        </div>
      </div>

      ${setupSteps("select")}

      <div class="setup-summary-grid">
        <div class="panel-card">
          <h3>参战玩家 <span class="muted-count">${players.length} / ${run.party.length}</span></h3>
          ${run.party.length === 0
            ? `<div class="empty small">队伍为空。添加玩家后，再逐个选入战斗。</div>`
            : run.party.map((member) => {
                const selected = draft.players.includes(member.id);
                return `
                  <button class="setup-person ${selected ? "on" : ""}" data-action="draft-player" data-player="${member.id}">
                    ${avatar(member.name, "sm")}
                    <span class="setup-person-body"><b>${escapeHtml(member.name)}</b><small>Lv ${member.level} · ${escapeHtml(member.role)}</small></span>
                    <span class="setup-add">${selected ? "已加入" : "＋ 添加"}</span>
                  </button>
                `;
              }).join("")}
          <button class="btn ghost small" style="width:100%;margin-top:6px" data-action="new-party-member">＋ 添加玩家</button>
        </div>
        <div class="panel-card">
          <h3>参战怪物 <span class="muted-count">${draft.monsters.length}</span></h3>
          <div class="monster-add-row">
            <button class="btn small" data-action="draft-monster" data-monster="guz">＋ 古兹</button>
            <button class="btn small" data-action="draft-monster" data-monster="wolf">＋ 狼</button>
            <button class="btn small" data-action="draft-monster" data-monster="bear">＋ 棕熊</button>
          </div>
          <div class="setup-monster-list">
            ${draft.monsters.length === 0
              ? `<div class="empty small">还没有添加怪物。逐个添加古兹、狼或棕熊。</div>`
              : draft.monsters.map((monster) => `
                  <span class="setup-monster">${escapeHtml(monster.name)}<button data-action="remove-draft-monster" data-draft="${monster.id}" aria-label="移除">×</button></span>
                `).join("")}
          </div>
        </div>
      </div>

      <div class="suggest-card wide">
        <span>建议组合</span>
        <b>${escapeHtml(suggestion.title)}</b>
        <small>${escapeHtml(suggestion.detail)}</small>
      </div>

      <div class="setup-actions">
        <button class="btn primary" data-action="next-initiative" ${total === 0 ? "disabled" : ""}>下一步：填写先攻 →</button>
        <button class="btn ghost" data-action="clear-draft" ${total === 0 ? "disabled" : ""}>清空参战者</button>
        <span class="setup-helper">玩家逐个加入，怪物逐个添加</span>
      </div>
    </section>
  `;
}

function initiativeEntryView(run) {
  const draft = ensureDraft(run);
  const rows = initiativeRows(run);
  const filled = rows.filter((row) => row.value !== "").length;
  return `
    <section class="fade-in">
      <div class="combat-head">
        <div>
          <p class="eyebrow">战斗筹备 / 填写先攻</p>
          <h1>玩家自己掷，你来填</h1>
          <p class="lede">玩家投 d20 + 先攻加值，把结果填进来；怪物先攻已由 App 自动掷好（d20 + 加值），不需要填写。</p>
        </div>
        <div class="combat-actions">
          <button class="btn primary" data-action="begin-combat" ${initiativeReady(run) ? "" : "disabled"}>开始战斗 →</button>
        </div>
      </div>

      ${setupSteps("initiative")}

      <div class="panel-card init-entry-card">
        <h3>先攻记录 <span class="muted-count"><span data-init-progress>${filled} / ${rows.length}</span></span></h3>
        ${rows.map((row) => `
          <label class="init-entry ${row.value !== "" ? "filled" : ""}">
            <span class="init-entry-name">
              ${avatar(row.name, "sm")}
              <span><b>${escapeHtml(row.name)}</b><small>${row.kindLabel} · 先攻加值 ${row.modifier >= 0 ? "+" : ""}${row.modifier} · ${escapeHtml(row.note)}</small></span>
            </span>
            ${row.editable
              ? `<input class="init-input" type="number" inputmode="numeric" min="-10" max="40" data-init-id="${row.id}" value="${escapeHtml(String(row.value))}" placeholder="—">`
              : `<span class="init-readonly">${escapeHtml(String(row.value || "—"))}</span>`}
          </label>
        `).join("")}
      </div>

      <div class="setup-actions">
        <button class="btn primary" data-action="begin-combat" ${initiativeReady(run) ? "" : "disabled"}>开始战斗 →</button>
        <button class="btn ghost" data-action="back-to-select">返回选择参战者</button>
        <span class="setup-helper">玩家先攻都填完后才能开始；怪物已自动掷好</span>
      </div>
    </section>
  `;
}

function rulesPanel() {
  return `
    <div class="panel-head"><h2>速查</h2><span>本冒险精选</span></div>
    ${RULES.map((rule) => `
      <div class="rule-card">
        <span>${escapeHtml(rule.category)}</span>
        <b>${escapeHtml(rule.term)}</b>
        <p>${escapeHtml(rule.summary)}</p>
      </div>
    `).join("")}
    <div class="note-hint">完整 SRD 不在 MVP 范围内；后续按内容包扩充规则卡。</div>
  `;
}

const NOTE_COLORS = ["yellow", "pink", "blue", "green"];
const NOTE_COLOR_LABELS = { yellow: "黄", pink: "粉", blue: "蓝", green: "绿" };

function relativeTime(timestamp) {
  const diff = Math.max(0, Date.now() - timestamp);
  if (diff < 60 * 1000) return "刚刚";
  if (diff < 60 * 60 * 1000) return `${Math.floor(diff / 60000)} 分钟前`;
  if (diff < 24 * 60 * 60 * 1000) return `${Math.floor(diff / 3600000)} 小时前`;
  return new Date(timestamp).toLocaleDateString("zh-CN", { month: "numeric", day: "numeric" });
}

function createPartyMember() {
  const name = (document.querySelector("#pm-name")?.value || "").trim();
  const role = (document.querySelector("#pm-role")?.value || "").trim() || "冒险者";
  const level = Number(document.querySelector("#pm-level")?.value);
  const ac = Number(document.querySelector("#pm-ac")?.value);
  const maxHp = Number(document.querySelector("#pm-hp")?.value);
  const initMod = Number(document.querySelector("#pm-init")?.value);
  const pp = Number(document.querySelector("#pm-pp")?.value);

  if (!name) { showToast("请先填写玩家姓名"); return; }
  if (!Number.isInteger(level) || level < 1 || level > 20) { showToast("等级需要是 1–20 的整数"); return; }
  if (!Number.isFinite(ac) || ac < 0) { showToast("AC 需要是 0 或更大的数字"); return; }
  if (!Number.isFinite(maxHp) || maxHp < 1) { showToast("最大 HP 需要至少为 1"); return; }
  if (!Number.isFinite(initMod)) { showToast("先攻加值需要是数字"); return; }
  if (!Number.isFinite(pp) || pp < 0) { showToast("被动感知需要是 0 或更大的数字"); return; }

  const run = getRun();
  run.party.push({
    id: `pc-${Date.now()}-${++partySeq}`,
    name,
    role,
    level,
    ac,
    maxHp,
    hp: maxHp,
    initMod,
    pp,
    conditions: [],
  });
  state.modal = null;
  render();
  flashSave();
  showToast(`已添加玩家：${name}`);
}

function newStickyNote() {
  const run = getRun();
  const note = {
    id: `note-${Date.now()}-${++stickySeq}`,
    text: "",
    color: "yellow",
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };
  run.stickyNotes.unshift(note);
  render();
  flashSave();
  requestAnimationFrame(() => document.querySelector(`[data-note-id="${note.id}"]`)?.focus());
}

function deleteStickyNote(id) {
  const run = getRun();
  run.stickyNotes = run.stickyNotes.filter((note) => note.id !== id);
  render();
  flashSave();
  showToast("便签已删除");
}

function setStickyColor(id, color) {
  const run = getRun();
  const note = run.stickyNotes.find((item) => item.id === id);
  if (!note) return;
  note.color = color;
  note.updatedAt = Date.now();
  render();
  flashSave();
}

function notesPanel(run) {
  const notes = run.stickyNotes || [];
  return `
    <div class="panel-head"><h2>便签</h2><span>${notes.length} 张 · 自动保存</span></div>
    <button class="btn primary" style="width:100%" data-action="new-note">＋ 新建便签</button>
    <div class="sticky-board">
      ${notes.length === 0
        ? `<div class="empty">还没有便签。写下第一条，把 NPC 秘密、临时裁定或下次继续的位置分开记。</div>`
        : notes.map((note) => `
            <div class="sticky-note ${note.color}">
              <textarea class="sticky-input" data-note-id="${note.id}" placeholder="写点什么……">${escapeHtml(note.text)}</textarea>
              <div class="sticky-foot">
                <div class="note-colors">
                  ${NOTE_COLORS.map((color) => `<button class="color-dot ${color} ${note.color === color ? "active" : ""}" data-action="note-color" data-note="${note.id}" data-color="${color}" title="${NOTE_COLOR_LABELS[color]}色便签" aria-label="${NOTE_COLOR_LABELS[color]}色便签"></button>`).join("")}
                </div>
                <span class="note-time">${relativeTime(note.updatedAt)}</span>
                <button class="note-delete" data-action="delete-note" data-note="${note.id}" aria-label="删除便签">×</button>
              </div>
            </div>
          `).join("")}
    </div>
    <div class="note-hint">只属于当前开团；每张便签独立保存。可写很多张，不再挤在一个大笔记里。</div>
  `;
}

function combatView(run) {
  if (!run.combat) return combatSetupView(run);

  const active = activeCombatant(run);
  const stat = monsterFor(active);
  const isMonster = Boolean(stat);
  return `
    <section class="fade-in">
      <div class="combat-head">
        <div>
          <p class="eyebrow">战斗 / 第 ${run.combat.round} 轮</p>
          <h1>${escapeHtml(ENCOUNTER.title)}</h1>
          <p class="lede">${escapeHtml(ENCOUNTER.summary)}</p>
        </div>
        <div class="combat-actions">
          <button class="btn primary" data-action="next-turn">下一回合 →</button>
          <button class="btn ghost" data-action="end-combat">结束战斗</button>
        </div>
      </div>

      <div class="active-card">
        <div class="active-head">
          ${avatar(active?.name || "?")}
          <div>
            <h2>${escapeHtml(active?.name || "—")}</h2>
            <p>${escapeHtml(active?.role || (isMonster ? "怪物" : "玩家角色"))}</p>
          </div>
          <span class="ac-badge">AC ${active?.ac ?? "—"}</span>
        </div>
        <div class="stat-line">
          <span>HP <b>${active?.hp ?? 0}</b> / ${active?.maxHp ?? 0}</span>
          <span>先攻 <b>${active?.initiative ?? "—"}</b></span>
          ${isMonster ? `<span>${escapeHtml(stat.speed)}</span>` : `<span>被动感知 ${active?.pp ?? "—"}</span>`}
        </div>
        <div class="damage-row">
          <button class="damage-btn" data-action="adjust-hp" data-delta="-1">−1</button>
          <button class="damage-btn" data-action="adjust-hp" data-delta="-5">−5</button>
          <button class="damage-btn" data-action="adjust-hp" data-delta="-10">−10</button>
          <button class="damage-btn heal" data-action="adjust-hp" data-delta="5">+5</button>
        </div>
        <div class="chip-row" style="margin-top:10px">
          ${["受擒", "倒地", "恐慌", "中毒"].map((condition) => `<button class="condition-toggle ${active?.conditions?.includes(condition) ? "on" : ""}" data-action="toggle-condition" data-condition="${condition}">${condition}</button>`).join("")}
        </div>
        ${isMonster ? "" : `<div class="combat-note">玩家角色卡仍由玩家保管；这里只同步 HP 与状态。</div>`}
      </div>

      <div class="combat-grid">
        <div class="panel-card">
          <h3>战斗日志</h3>
          <ul class="log-list">
            ${run.combat.log.slice(0, 8).map((entry) => `<li>${escapeHtml(entry)}</li>`).join("")}
          </ul>
        </div>
        <div class="panel-card">
          <h3>${isMonster ? "数据块 · " + escapeHtml(stat.name) : "本场提示"}</h3>
          ${
            isMonster
              ? `<ul class="stat-traits">
                   <li>${escapeHtml(stat.meta)}</li>
                   ${stat.traits.map(([name, text]) => `<li><b>${escapeHtml(name)}。</b>${escapeHtml(text)}</li>`).join("")}
                   <li style="margin-top:6px;color:#9a672d">${escapeHtml(stat.tactics.join(" "))}</li>
                 </ul>`
              : `<ul class="stat-traits">${ENCOUNTER.tactics.map((tactic) => `<li>${escapeHtml(tactic)}</li>`).join("")}</ul><div class="combat-note">App 不自动判命中、豁免或规则；DM 用骰子或实体骰。</div>`
          }
        </div>
      </div>

      <div class="action-strip">
        <span class="label">常用动作</span>
        <div class="chip-row">
          ${["攻击", "施法", "闪避", "协助", "准备", "撤离"].map((hint) => `<button class="action-chip" data-action="combat-hint" data-hint="${hint}">${hint}</button>`).join("")}
        </div>
      </div>

      <div class="combat-party">
        <div class="panel-head"><h2>队伍状态</h2><span>同步到开团记录</span></div>
        <div class="combat-party-grid">
          ${run.party.map((member) => partyRow(member)).join("")}
        </div>
      </div>
    </section>
  `;
}

function mapView(run) {
  const pin = MAP.pins.find((item) => item.id === state.selectedPinId);
  return `
    <section class="fade-in">
      <div class="scene-head">
        <div class="scene-kicker"><span class="tag red">地图</span><span class="tag">DM 参考</span><span class="tag green">图钉不烧录</span></div>
        <h1>${escapeHtml(MAP.title)}</h1>
        <p class="lede">静态地图 + 图钉。战斗仍建议实体模型或 theater of mind；这里不替代 VTT。</p>
      </div>

      <div class="map-toolbar">
        <span class="hint">点击图钉查看房间提示 · ${MAP.pins.length} 个点位</span>
        <button class="btn primary" data-action="export-map">↗ 导出 / 分享原图</button>
      </div>

      <div class="map-stage">
        <img src="${MAP.image}" alt="诺克的树屋宅院地图">
        ${MAP.pins.map((item, index) => `
          <button class="map-pin ${item.dmOnly ? "dm" : ""} ${pin?.id === item.id ? "active" : ""}" style="left:${item.x * 100}%;top:${item.y * 100}%" data-action="select-pin" data-pin="${item.id}" title="${escapeHtml(item.label)}">${index + 1}</button>
        `).join("")}
      </div>

      <div class="map-legend">
        ${MAP.pins.map((item, index) => `
          <button class="${pin?.id === item.id ? "active" : ""}" data-action="select-pin" data-pin="${item.id}">
            <span class="num">${index + 1}</span>
            <span>${escapeHtml(item.label)}</span>
            ${item.dmOnly ? `<span class="dm">DM</span>` : ""}
          </button>
        `).join("")}
      </div>

      ${pin ? `
        <div class="pin-detail">
          <div>
            <h3>${escapeHtml(pin.label)} ${pin.dmOnly ? `<span class="tag red">DM-only</span>` : ""}</h3>
            <p>${escapeHtml(pin.description)}</p>
          </div>
          <button class="close" data-action="select-pin" data-pin="" aria-label="关闭">×</button>
        </div>
      ` : `<div class="map-note">图钉只存在于 App 内；导出的是干净原图。玩家展示请用导出/分享/打印，App 内不做玩家视图。</div>`}
    </section>
  `;
}

function statusbar(run) {
  const combatHint = run?.combat && run.mode === "combat" ? "N 下一回合" : "Esc 遮屏恢复";
  return `
    <footer class="statusbar">
      <span id="save-status"><span class="save-dot"></span>${escapeHtml(state.saveLabel)}</span>
      <span>内容 v${escapeHtml(ADVENTURE.version)}</span>
      <span>本地 · 无账号</span>
      <span class="spacer"></span>
      <span>${combatHint}</span>
      <span>原型 · 信息架构验证</span>
    </footer>
  `;
}

/* ---------- overlays ---------- */

function renderOverlays() {
  const root = document.getElementById("overlay-root");
  if (!root) return;
  if (state.privacy) {
    root.innerHTML = `
      <div class="privacy-overlay" data-action="restore-privacy">
        <strong>已遮屏</strong>
        <span>点击任意处或按 Esc 恢复</span>
      </div>
    `;
    return;
  }
  if (!state.modal) {
    root.innerHTML = "";
    return;
  }
  root.innerHTML = modalBackdrop(state.modal);
}

function modalBackdrop(modal) {
  let content = "";
  if (modal.type === "new-run") content = newRunModal();
  if (modal.type === "party-member") content = partyMemberModal();
  if (modal.type === "switch") content = switchModal();
  if (modal.type === "npc") content = npcModal();
  if (modal.type === "export") content = exportModal();
  return `
    <div class="modal-backdrop" data-action="close-modal">
      <div class="modal-card" data-stop>${content}</div>
    </div>
  `;
}

function partyMemberModal() {
  return `
    <div class="modal-head">
      <div><p class="eyebrow">队伍 / 添加玩家</p><h2>添加一名玩家</h2></div>
      <button class="modal-close" data-action="close-modal" aria-label="关闭">×</button>
    </div>
    <p>这里只记录战斗需要的最小数值，不会创建完整角色卡。</p>
    <label class="field-label" for="pm-name">姓名</label>
    <input class="input" id="pm-name" placeholder="例如：阿岚" autofocus>
    <label class="field-label" for="pm-role">职业 / 定位（可选）</label>
    <input class="input" id="pm-role" placeholder="例如：战士">
    <div class="form-grid">
      <div><label class="field-label" for="pm-level">等级</label><input class="input" id="pm-level" type="number" value="4" min="1" max="20"></div>
      <div><label class="field-label" for="pm-ac">AC</label><input class="input" id="pm-ac" type="number" value="14" min="0"></div>
      <div><label class="field-label" for="pm-hp">最大 HP</label><input class="input" id="pm-hp" type="number" value="20" min="1"></div>
      <div><label class="field-label" for="pm-init">先攻加值</label><input class="input" id="pm-init" type="number" value="0" step="1"></div>
      <div><label class="field-label" for="pm-pp">被动感知</label><input class="input" id="pm-pp" type="number" value="12" min="0"></div>
    </div>
    <div class="modal-actions">
      <button class="btn ghost" data-action="close-modal">取消</button>
      <button class="btn primary" data-action="create-party-member">添加玩家</button>
    </div>
  `;
}

function newRunModal() {
  return `
    <div class="modal-head">
      <div><p class="eyebrow">新建开团</p><h2>从空白开始</h2></div>
      <button class="modal-close" data-action="close-modal" aria-label="关闭">×</button>
    </div>
    <p>新建记录完全空白；队伍、flags、战斗状态和笔记都不会从旧团复制。</p>
    <label class="field-label" for="new-run-name">开团名称</label>
    <input class="input" id="new-run-name" value="${escapeHtml(state.newRunName)}" placeholder="例如：周五团 · B 组" autofocus>
    <div class="modal-actions">
      <button class="btn ghost" data-action="close-modal">取消</button>
      <button class="btn primary" data-action="create-run">创建空白开团</button>
    </div>
  `;
}

function switchModal() {
  const target = state.pending?.type === "run" ? runs[state.pending.runId]?.name : "我的开团";
  return `
    <div class="modal-head">
      <div><p class="eyebrow">切换开团</p><h2>战斗尚未结束</h2></div>
      <button class="modal-close" data-action="close-modal" aria-label="关闭">×</button>
    </div>
    <p>当前战斗会先自动保存，再切换到「${escapeHtml(target)}」。回来后仍会保留完整的战斗状态。</p>
    <div class="modal-actions">
      <button class="btn ghost" data-action="close-modal">继续战斗</button>
      <button class="btn primary" data-action="confirm-switch">保存并切换</button>
    </div>
  `;
}

function npcModal() {
  return `
    <div class="modal-head">
      <div><p class="eyebrow">NPC / 扮演卡</p><h2>${escapeHtml(NPC.name)}</h2></div>
      <button class="modal-close" data-action="close-modal" aria-label="关闭">×</button>
    </div>
    <div class="npc-meta">
      <span class="tag red">${escapeHtml(NPC.role)}</span>
      <span class="tag green">${escapeHtml(NPC.attitude)}</span>
      <span class="tag">本地 · DM-only</span>
    </div>
    <p class="npc-public">${escapeHtml(NPC.public)}</p>
    <p class="npc-public"><b>语气：</b>${escapeHtml(NPC.voice)}</p>
    <div class="secret-box">
      <div style="display:flex;justify-content:space-between;gap:12px;align-items:center">
        <span class="label">DM 秘密</span>
        <button class="btn ghost small" data-action="toggle-secrets">${state.showSecrets ? "隐藏秘密" : "显示秘密"}</button>
      </div>
      ${state.showSecrets ? `<p>${escapeHtml(NPC.dm)}</p><p><b>秘密：</b>${NPC.secrets.map(escapeHtml).join("；")}</p>` : `<p>秘密已隐藏。玩家看向屏幕时，可直接用「遮屏」。</p>`}
    </div>
    <ul class="sample-lines">${NPC.lines.map((line) => `<li>${escapeHtml(line)}</li>`).join("")}</ul>
    <div class="modal-actions">
      <button class="btn ghost" data-action="close-modal">关闭</button>
    </div>
  `;
}

function exportModal() {
  return `
    <div class="modal-head">
      <div><p class="eyebrow">导出 / 分享</p><h2>树屋地图</h2></div>
      <button class="modal-close" data-action="close-modal" aria-label="关闭">×</button>
    </div>
    <div class="export-row">
      <img src="${MAP.image}" alt="">
      <div><b>荒野逐羊_树屋地图.jpg</b><span>1280 × 736 · JPG · 干净原图</span><span>Pyromancer's Dungeon Painter</span></div>
    </div>
    <p>图钉、DM 标注和秘密不会烧录进图片。保存到指定目录或通过系统分享面板发送到其他 App。</p>
    <div class="modal-actions">
      <a class="btn primary" href="${MAP.image}" download="荒野逐羊_树屋地图.jpg">保存原图</a>
      <button class="btn" data-action="share-map">分享…</button>
      <button class="btn ghost" data-action="close-modal">取消</button>
    </div>
  `;
}

/* ---------- actions ---------- */

document.addEventListener("click", (event) => {
  const target = event.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;

  if (action === "close-modal" && target.classList.contains("modal-backdrop") && event.target.closest(".modal-card")) {
    return;
  }

  event.preventDefault();

  if (action === "open-run") {
    const id = target.dataset.run;
    openRun(id);
  } else if (action === "library") {
    goLibrary();
  } else if (action === "new-run") {
    state.modal = { type: "new-run" };
    state.newRunName = "";
    renderOverlays();
  } else if (action === "create-run") {
    createRun();
  } else if (action === "close-modal") {
    state.modal = null;
    state.pending = null;
    renderOverlays();
  } else if (action === "confirm-switch") {
    confirmSwitch();
  } else if (action === "privacy") {
    state.privacy = true;
    renderOverlays();
  } else if (action === "restore-privacy") {
    state.privacy = false;
    renderOverlays();
  } else if (action === "mode") {
    setMode(target.dataset.mode);
  } else if (action === "select-scene") {
    const run = getRun();
    const scene = sceneById(target.dataset.scene);
    run.sceneId = scene.id;
    run.beatId = scene.beats[0].id;
    run.mode = "scene";
    state.inspector = "party";
    state.resetScroll = true;
    render();
    flashSave();
  } else if (action === "select-beat") {
    const run = getRun();
    run.beatId = target.dataset.beat;
    run.mode = "scene";
    render();
    flashSave();
  } else if (action === "tab") {
    const run = getRun();
    state.inspector = target.dataset.tab;
    if (target.dataset.tab === "battle") {
      if (!run.combat) ensureDraft(run);
      run.mode = "combat";
    }
    render();
  } else if (action === "toggle-flag") {
    const run = getRun();
    const flag = target.dataset.flag;
    run.flags[flag] = !run.flags[flag];
    render();
    flashSave();
  } else if (action === "new-party-member") {
    state.modal = { type: "party-member" };
    renderOverlays();
  } else if (action === "create-party-member") {
    createPartyMember();
  } else if (action === "new-note") {
    newStickyNote();
  } else if (action === "delete-note") {
    deleteStickyNote(target.dataset.note);
  } else if (action === "note-color") {
    setStickyColor(target.dataset.note, target.dataset.color);
  } else if (action === "open-npc") {
    state.modal = { type: "npc" };
    state.showSecrets = false;
    renderOverlays();
  } else if (action === "toggle-secrets") {
    state.showSecrets = !state.showSecrets;
    renderOverlays();
  } else if (action === "open-combat") {
    openCombatSetup();
  } else if (action === "draft-player") {
    toggleDraftPlayer(target.dataset.player);
  } else if (action === "draft-monster") {
    addDraftMonster(target.dataset.monster);
    render();
    flashSave();
  } else if (action === "remove-draft-monster") {
    const run = getRun();
    if (run.combatDraft) {
      run.combatDraft.monsters = run.combatDraft.monsters.filter((monster) => monster.id !== target.dataset.draft);
      delete run.combatDraft.initiative[target.dataset.draft];
      render();
      flashSave();
    }
  } else if (action === "clear-draft") {
    clearDraft();
  } else if (action === "next-initiative") {
    goInitiativeStage();
  } else if (action === "back-to-select") {
    backToSelect();
  } else if (action === "begin-combat") {
    startCombatFromDraft();
  } else if (action === "next-turn") {
    nextTurn();
  } else if (action === "select-combatant") {
    const run = getRun();
    if (run.combat) {
      run.combat.activeId = target.dataset.combatant;
      render();
      flashSave();
    }
  } else if (action === "adjust-hp") {
    adjustHp(Number(target.dataset.delta));
  } else if (action === "toggle-condition") {
    toggleCondition(target.dataset.condition);
  } else if (action === "roll-dice") {
    rollDice(target.dataset.mode);
  } else if (action === "end-combat") {
    endCombat();
  } else if (action === "select-pin") {
    state.selectedPinId = target.dataset.pin || null;
    render();
  } else if (action === "export-map") {
    state.modal = { type: "export" };
    renderOverlays();
  } else if (action === "combat-hint") {
    showToast(`原型：${target.dataset.hint} 的规则卡/操作会放在这里`);
  } else if (action === "share-map") {
    state.modal = null;
    renderOverlays();
    showToast("原型：这里会调用 macOS / iPadOS 的系统分享面板");
  } else if (action === "reset-demo") {
    resetDemo();
  }
});

document.addEventListener("input", (event) => {
  if (event.target.id === "new-run-name") {
    state.newRunName = event.target.value;
  }
  if (event.target.matches("[data-note-id]")) {
    const run = getRun();
    const note = run.stickyNotes?.find((item) => item.id === event.target.dataset.noteId);
    if (note) {
      note.text = event.target.value;
      note.updatedAt = Date.now();
      flashSave();
    }
  }
  if (event.target.matches("[data-init-id]")) {
    const run = getRun();
    const draft = ensureDraft(run);
    draft.initiative[event.target.dataset.initId] = event.target.value;
    event.target.closest(".init-entry")?.classList.toggle("filled", event.target.value !== "");
    updateInitiativeReady();
    flashSave();
  }
});

document.addEventListener("keydown", (event) => {
  const isTyping = ["INPUT", "TEXTAREA"].includes(event.target.tagName);

  if (event.key === "Escape") {
    if (state.privacy) {
      state.privacy = false;
      renderOverlays();
      return;
    }
    if (state.modal) {
      state.modal = null;
      state.pending = null;
      renderOverlays();
    }
    return;
  }

  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
    event.preventDefault();
    showToast("原型：全局搜索尚未接入");
    return;
  }

  if (!isTyping && !state.modal && !state.privacy && state.screen === "run" && getRun().mode === "combat" && event.key.toLowerCase() === "n") {
    nextTurn();
  }
});

function openRun(id) {
  if (!runs[id]) return;
  const current = getRun();
  if (state.screen === "run" && current.combat && current.id !== id) {
    state.pending = { type: "run", runId: id };
    state.modal = { type: "switch" };
    renderOverlays();
    return;
  }
  state.activeRunId = id;
  state.screen = "run";
  const run = getRun();
  run.lastPlayed = "刚刚";
  run.mode = run.mode || "scene";
  state.inspector = run.combat || run.mode === "combat" ? "battle" : "party";
  state.selectedPinId = null;
  render();
  flashSave();
}

function goLibrary() {
  const run = getRun();
  if (state.screen === "run" && run?.combat) {
    state.pending = { type: "library" };
    state.modal = { type: "switch" };
    renderOverlays();
    return;
  }
  state.screen = "library";
  state.modal = null;
  state.inspector = "party";
  render();
}

function confirmSwitch() {
  const pending = state.pending;
  state.modal = null;
  state.pending = null;
  if (!pending) return;
  if (pending.type === "library") {
    state.screen = "library";
    render();
    return;
  }
  if (pending.type === "run" && runs[pending.runId]) {
    state.activeRunId = pending.runId;
    state.screen = "run";
    const run = getRun();
    run.mode = run.mode || "scene";
    state.inspector = run.combat || run.mode === "combat" ? "battle" : "party";
    render();
    flashSave();
  }
}

function setMode(mode) {
  const run = getRun();
  if (!run) return;
  if (mode === "combat") {
    ensureDraft(run);
    state.inspector = "battle";
  } else if (mode === "map") {
    state.inspector = "party";
  } else {
    state.inspector = "party";
  }
  run.mode = mode;
  render();
  flashSave();
}

function nextTurn() {
  const run = getRun();
  if (!run.combat) {
    openCombatSetup();
    return;
  }
  const list = run.combat.combatants;
  const index = list.findIndex((item) => item.id === run.combat.activeId);
  const next = (index + 1) % list.length;
  if (next === 0) run.combat.round += 1;
  run.combat.activeId = list[next].id;
  run.combat.log.unshift(`第 ${run.combat.round} 轮 · ${list[next].name} 的回合`);
  render();
  flashSave();
}

function adjustHp(delta) {
  const run = getRun();
  const active = activeCombatant(run);
  if (!active) return;
  const before = active.hp;
  active.hp = Math.max(0, Math.min(active.maxHp, active.hp + delta));
  if (active.hp === 0 && !active.conditions.includes("倒地")) {
    active.conditions.push("倒地");
  }
  if (delta > 0 && active.hp > 0) {
    active.conditions = active.conditions.filter((condition) => condition !== "倒地");
  }
  run.combat.log.unshift(`第 ${run.combat.round} 轮 · ${active.name} ${delta > 0 ? "+" : ""}${delta} HP（${before} → ${active.hp}）`);
  syncParty(run);
  render();
  flashSave();
}

function toggleCondition(condition) {
  const run = getRun();
  const active = activeCombatant(run);
  if (!active) return;
  if (active.conditions.includes(condition)) {
    active.conditions = active.conditions.filter((item) => item !== condition);
    run.combat.log.unshift(`${active.name} 移除状态：${condition}`);
  } else {
    active.conditions.push(condition);
    run.combat.log.unshift(`${active.name} 获得状态：${condition}`);
  }
  syncParty(run);
  render();
  flashSave();
}

function rollDice(mode) {
  const run = getRun();
  if (!run.combat) return;
  const roll = () => 1 + Math.floor(Math.random() * 20);
  const first = roll();
  let result = first;
  let suffix = "";
  if (mode === "adv" || mode === "dis") {
    const second = roll();
    result = mode === "adv" ? Math.max(first, second) : Math.min(first, second);
    suffix = `（${first}, ${second}）`;
  }
  const label = mode === "adv" ? "优势" : mode === "dis" ? "劣势" : "d20";
  run.combat.log.unshift(`掷骰 · ${label} = ${result}${suffix}`);
  render();
  flashSave();
  showToast(`${label}：${result}${suffix}`);
}

function endCombat() {
  const run = getRun();
  if (!run.combat) return;
  syncParty(run);
  run.combat = null;
  run.combatDraft = null;
  run.mode = "scene";
  state.inspector = "party";
  render();
  flashSave();
  showToast("战斗结束，队伍 HP 与状态已同步");
}

function createRun() {
  const name = (state.newRunName || "").trim() || "未命名开团";
  const id = `run-${Date.now()}`;
  runs[id] = {
    id,
    name,
    lastPlayed: "刚刚",
    status: "waiting",
    statusLabel: "待开团",
    sceneId: "scene-1",
    beatId: "sheep-arrives",
    mode: "scene",
    party: [],
    flags: {},
    combat: null,
    combatDraft: null,
    stickyNotes: [],
    sessions: 0,
  };
  state.activeRunId = id;
  state.screen = "run";
  state.inspector = "party";
  state.modal = null;
  state.newRunName = "";
  state.resetScroll = true;
  render();
  flashSave();
  showToast("已创建空白开团；队伍需要在右侧手动录入");
}

function resetDemo() {
  runs = initialRuns();
  state = {
    screen: "library",
    activeRunId: "fri-a",
    inspector: "party",
    modal: null,
    privacy: false,
    selectedPinId: null,
    showSecrets: false,
    saveLabel: "已保存",
    pending: null,
    newRunName: "",
    resetScroll: true,
  };
  if (location.hash) history.replaceState(null, "", location.pathname);
  render();
  showToast("演示数据已重置");
}

/* ---------- hash 入口（便于截图 / 直接打开某个视图） ---------- */

function applyHash() {
  const hash = location.hash.replace("#", "");
  state.modal = null;
  state.pending = null;
  state.privacy = false;
  state.selectedPinId = null;

  if (["run", "combat", "fight", "map", "npc", "export", "new-run", "privacy"].includes(hash)) {
    state.screen = "run";
    state.activeRunId = "fri-a";
    const run = getRun();
    run.sceneId = "scene-2";
    run.beatId = "guz-arrives";
    state.inspector = "party";
    if (hash === "combat") {
      ensureDraft(run);
      run.mode = "combat";
      state.inspector = "battle";
    } else if (hash === "fight") {
      ensureDemoCombat(run);
      run.mode = "combat";
      state.inspector = "battle";
    } else if (hash === "map") {
      run.mode = "map";
    } else if (hash === "export") {
      run.mode = "map";
      state.modal = { type: "export" };
    } else if (hash === "npc") {
      run.mode = "scene";
      state.modal = { type: "npc" };
    } else if (hash === "new-run") {
      run.mode = "scene";
      state.modal = { type: "new-run" };
    } else if (hash === "privacy") {
      run.mode = "scene";
      state.privacy = true;
    } else {
      run.mode = "scene";
    }
  } else {
    state.screen = "library";
    state.inspector = "party";
  }
  render();
}

window.addEventListener("hashchange", applyHash);
applyHash();
