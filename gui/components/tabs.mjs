import { div, makeComponent, span } from "../jsgui.mjs";

// tabs
export const tabs = makeComponent(function tabs(props) {
  const {options, setSelectedId} = props;
  let {selectedId} = props;
  if (selectedId == null) selectedId = options[0].id ?? 0;
  const tabsHeader = this.append(div({className: "tabs-header"}));
  options.forEach((option, i) => {
    const optionId = option.id ?? i;
    tabsHeader.append(span(option.label, {
      key: optionId,
      href: option.href,
      className: "tabs-option",
      attribute: {dataSelected: optionId === selectedId, title: option.label},
      events: {click: () => setSelectedId(optionId)},
    }));
  });
});
