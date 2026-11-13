var categoryOptions = [
  { value: "", label: "No category" },
  { value: "task", label: "task" },
  { value: "event", label: "event" },
  { value: "fact", label: "fact" },
  { value: "emotion", label: "emotion" },
  { value: "idea", label: "idea" },
  { value: "question", label: "question" }
];
var categoryValues = categoryOptions.map(function(option) { return option.value; });

function normalizedCategory(category) {
  var value = String(category || "").trim();
  return categoryValues.indexOf(value) !== -1 ? value : "";
}

function captureArguments(category, now) {
  if (category instanceof Date) {
    return { category: "", now: category };
  }
  return { category: normalizedCategory(category), now: now || new Date() };
}

function eventInput(text) {
  var value = String(text).replace(/\r\n?/g, "\n").trim();
  var match = /^(\d{1,2}):(\d{2})(?=$|[\s—–-])/.exec(value);
  if (match && Number(match[1]) < 24 && Number(match[2]) < 60) {
    return {
      time: match[0],
      text: value.slice(match[0].length).replace(/^\s*[-–—]?\s*/, ""),
      invalidTime: false
    };
  }
  return { time: "", text: value, invalidTime: /^\d+:/.test(value) };
}

function bullet(text, category, now, date) {
  var args = captureArguments(category, now);
  var value = String(text).replace(/\r\n?/g, "\n").trim();
  if (!value) return "";
  if (args.category === "event") {
    var event = eventInput(value);
    return "- " + (event.time ? event.time + " " : "") + "[event]" + (event.text ? " " + event.text.split("\n").join("\n  ") : "");
  }
  var categoryPrefix = args.category ? "[" + args.category + "] " : "";
  return "- " + categoryPrefix + value.split("\n").join("\n  ");
}

function localDate(now) {
  return now.getFullYear() + "-" + ("0" + (now.getMonth() + 1)).slice(-2) + "-" + ("0" + now.getDate()).slice(-2);
}

function validDate(date) {
  if (typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
  var parsed = new Date(date + "T12:00:00");
  return !isNaN(parsed.getTime()) && localDate(parsed) === date;
}

function captureId(now) {
  now = now || new Date();
  var prefix = localDate(now).replace(/-/g, "") + ("0" + now.getHours()).slice(-2) + ("0" + now.getMinutes()).slice(-2);
  return prefix;
}

function newRequestId() {
  var token = "";
  for (var i = 0; i < 2; i++)
    token += ("00000000" + Math.floor(Math.random() * 0x100000000).toString(16)).slice(-8);
  return token;
}

function request(text, category, now, date, id, requestId) {
  now = now || new Date();
  date = date === undefined ? localDate(now) : date;
  if (typeof text !== "string" || !text.trim() || text.length > 8000 || text.indexOf("\0") >= 0 ||
      !validDate(date) || !/^\d{12}$/.test(id || "") || !/^[a-f0-9]{16}$/.test(requestId || "") || isNaN(now.getTime())) return null;
  return {id: id, requestId: requestId, text: text, category: normalizedCategory(category), capturedAt: now.toISOString(), contextDate: date};
}

function saveCommand(text, category, now, date, id, helperPath, requestId) {
  if (!request(text, category, now, date, id, requestId) || !helperPath) return [];
  return ["python3", helperPath];
}

if (typeof module !== "undefined") module.exports = {
  saveCommand: saveCommand,
  request: request,
  captureId: captureId,
  newRequestId: newRequestId,
  bullet: bullet,
  eventInput: eventInput,
  categoryOptions: categoryOptions
};
