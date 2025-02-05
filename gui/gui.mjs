import { tabs } from "./components/tabs.mjs";
import { div, makeComponent, renderRoot, span } from "./jsgui.mjs";

function useGetRequest(options) {
  const {state, setState, key, fetch, onError = () => {}} = options;
  const loadingKey = key + 'Loading';
  if (state[loadingKey] === undefined) {
    state[loadingKey] = true;
    fetch()
      .then((newValue) => setState({[key]: newValue, [loadingKey]: false}))
      .catch((error) => {
        console.error(error);
        onError(error);
        setState({[loadingKey]: false})
      });
  }
}
function strings_unescape(str) {
  return str.replaceAll(/\\(.)/g, (_, g1) => g1);
}
function parseCsv(csv, mapRow) {
  const rows = [];
  let csvRowStart = 0;
  let csvRowEnd = 0;
  while (csvRowEnd < csv.length - 1) {
    let row = [];
    csvRowEnd = csv.slice(csvRowStart).indexOf("\n"); // TODO: support other newlines?
    if (csvRowEnd === -1) csvRowEnd = csv.length;
    else {csvRowEnd = csvRowStart + csvRowEnd}
    const csvRow = csv.slice(csvRowStart, csvRowEnd);
    const jMax = csvRowEnd - csvRowStart;
    let i = 0;
    let j = 0;
    for (; j < jMax; j++) {
      const char = csvRow[j];
      if (char === ",") {
        let cell = csvRow.slice(i, j).trim();
        if (cell[0] === "\"") cell = strings_unescape(cell.slice(1, -1));
        row.push(cell);
        i = j + 1;
      } else if (char === "\"") {
        for (j += 1; j < jMax; j++) {
          const char2 = csvRow[j];
          if (char2 === "\"") {
            break;
          } else if (char2 === "\\") {
            j += 1;
          }
        }
      }
    }
    rows.push(mapRow(row));
    csvRowStart = csvRowEnd + 1;
  }
  return rows;
}

const root = makeComponent(function root() {
  const [state, setState] = this.useState({
    data: [],
    dataLoading: undefined,
  });
  useGetRequest({
    state,
    setState,
    key: 'data',
    fetch: async () => {
      const dataCsv = await (await fetch("/apps.csv")).text();
      return parseCsv(dataCsv, (row) => {
        const [appId, appName, ...tags] = row;
        return [+appId, appName, ...tags];
      });
    },
  })
  console.log('state', state)
  const wrapper = this.append(div({
    style: {padding: 8, display: 'flex', flexDirection: 'column'},
  }));
  wrapper.append(tabs({
    options: [
      {label: 'Table'},
    ]
  }))
  wrapper.append(span("Hello world"));
});
renderRoot(root());
