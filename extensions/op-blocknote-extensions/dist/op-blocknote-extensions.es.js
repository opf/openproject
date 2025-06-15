import te, { useState as p, useRef as fe, useEffect as le, useCallback as xe } from "react";
import { insertOrUpdateBlock as ve } from "@blocknote/core";
import { createReactBlockSpec as je } from "@blocknote/react";
var ae = { exports: {} }, K = {};
/**
 * @license React
 * react-jsx-runtime.production.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var he;
function ye() {
  if (he) return K;
  he = 1;
  var o = Symbol.for("react.transitional.element"), P = Symbol.for("react.fragment");
  function v(N, d, f) {
    var h = null;
    if (f !== void 0 && (h = "" + f), d.key !== void 0 && (h = "" + d.key), "key" in d) {
      f = {};
      for (var x in d)
        x !== "key" && (f[x] = d[x]);
    } else f = d;
    return d = f.ref, {
      $$typeof: o,
      type: N,
      key: h,
      ref: d !== void 0 ? d : null,
      props: f
    };
  }
  return K.Fragment = P, K.jsx = v, K.jsxs = v, K;
}
var ee = {};
/**
 * @license React
 * react-jsx-runtime.development.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var me;
function ke() {
  return me || (me = 1, process.env.NODE_ENV !== "production" && function() {
    function o(e) {
      if (e == null) return null;
      if (typeof e == "function")
        return e.$$typeof === Y ? null : e.displayName || e.name || null;
      if (typeof e == "string") return e;
      switch (e) {
        case C:
          return "Fragment";
        case J:
          return "Profiler";
        case ne:
          return "StrictMode";
        case W:
          return "Suspense";
        case w:
          return "SuspenseList";
        case q:
          return "Activity";
      }
      if (typeof e == "object")
        switch (typeof e.tag == "number" && console.error(
          "Received an unexpected object in getComponentNameFromType(). This is likely a bug in React. Please file an issue."
        ), e.$$typeof) {
          case T:
            return "Portal";
          case ce:
            return (e.displayName || "Context") + ".Provider";
          case _:
            return (e._context.displayName || "Context") + ".Consumer";
          case $:
            var n = e.render;
            return e = e.displayName, e || (e = n.displayName || n.name || "", e = e !== "" ? "ForwardRef(" + e + ")" : "ForwardRef"), e;
          case H:
            return n = e.displayName || null, n !== null ? n : o(e.type) || "Memo";
          case A:
            n = e._payload, e = e._init;
            try {
              return o(e(n));
            } catch {
            }
        }
      return null;
    }
    function P(e) {
      return "" + e;
    }
    function v(e) {
      try {
        P(e);
        var n = !1;
      } catch {
        n = !0;
      }
      if (n) {
        n = console;
        var c = n.error, i = typeof Symbol == "function" && Symbol.toStringTag && e[Symbol.toStringTag] || e.constructor.name || "Object";
        return c.call(
          n,
          "The provided key is an unsupported type %s. This value must be coerced to a string before using it here.",
          i
        ), P(e);
      }
    }
    function N(e) {
      if (e === C) return "<>";
      if (typeof e == "object" && e !== null && e.$$typeof === A)
        return "<...>";
      try {
        var n = o(e);
        return n ? "<" + n + ">" : "<...>";
      } catch {
        return "<...>";
      }
    }
    function d() {
      var e = D.A;
      return e === null ? null : e.getOwner();
    }
    function f() {
      return Error("react-stack-top-frame");
    }
    function h(e) {
      if (M.call(e, "key")) {
        var n = Object.getOwnPropertyDescriptor(e, "key").get;
        if (n && n.isReactWarning) return !1;
      }
      return e.key !== void 0;
    }
    function x(e, n) {
      function c() {
        V || (V = !0, console.error(
          "%s: `key` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://react.dev/link/special-props)",
          n
        ));
      }
      c.isReactWarning = !0, Object.defineProperty(e, "key", {
        get: c,
        configurable: !0
      });
    }
    function y() {
      var e = o(this.type);
      return X[e] || (X[e] = !0, console.error(
        "Accessing element.ref was removed in React 19. ref is now a regular prop. It will be removed from the JSX Element type in a future release."
      )), e = this.props.ref, e !== void 0 ? e : null;
    }
    function re(e, n, c, i, b, m, U, B) {
      return c = m.ref, e = {
        $$typeof: O,
        type: e,
        key: n,
        props: m,
        _owner: b
      }, (c !== void 0 ? c : null) !== null ? Object.defineProperty(e, "ref", {
        enumerable: !1,
        get: y
      }) : Object.defineProperty(e, "ref", { enumerable: !1, value: null }), e._store = {}, Object.defineProperty(e._store, "validated", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: 0
      }), Object.defineProperty(e, "_debugInfo", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: null
      }), Object.defineProperty(e, "_debugStack", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: U
      }), Object.defineProperty(e, "_debugTask", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: B
      }), Object.freeze && (Object.freeze(e.props), Object.freeze(e)), e;
    }
    function z(e, n, c, i, b, m, U, B) {
      var u = n.children;
      if (u !== void 0)
        if (i)
          if (se(u)) {
            for (i = 0; i < u.length; i++)
              j(u[i]);
            Object.freeze && Object.freeze(u);
          } else
            console.error(
              "React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead."
            );
        else j(u);
      if (M.call(n, "key")) {
        u = o(e);
        var S = Object.keys(n).filter(function(oe) {
          return oe !== "key";
        });
        i = 0 < S.length ? "{key: someKey, " + S.join(": ..., ") + ": ...}" : "{key: someKey}", L[u + i] || (S = 0 < S.length ? "{" + S.join(": ..., ") + ": ...}" : "{}", console.error(
          `A props object containing a "key" prop is being spread into JSX:
  let props = %s;
  <%s {...props} />
React keys must be passed directly to JSX without using spread:
  let props = %s;
  <%s key={someKey} {...props} />`,
          i,
          u,
          S,
          u
        ), L[u + i] = !0);
      }
      if (u = null, c !== void 0 && (v(c), u = "" + c), h(n) && (v(n.key), u = "" + n.key), "key" in n) {
        c = {};
        for (var G in n)
          G !== "key" && (c[G] = n[G]);
      } else c = n;
      return u && x(
        c,
        typeof e == "function" ? e.displayName || e.name || "Unknown" : e
      ), re(
        e,
        u,
        m,
        b,
        d(),
        c,
        U,
        B
      );
    }
    function j(e) {
      typeof e == "object" && e !== null && e.$$typeof === O && e._store && (e._store.validated = 1);
    }
    var k = te, O = Symbol.for("react.transitional.element"), T = Symbol.for("react.portal"), C = Symbol.for("react.fragment"), ne = Symbol.for("react.strict_mode"), J = Symbol.for("react.profiler"), _ = Symbol.for("react.consumer"), ce = Symbol.for("react.context"), $ = Symbol.for("react.forward_ref"), W = Symbol.for("react.suspense"), w = Symbol.for("react.suspense_list"), H = Symbol.for("react.memo"), A = Symbol.for("react.lazy"), q = Symbol.for("react.activity"), Y = Symbol.for("react.client.reference"), D = k.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE, M = Object.prototype.hasOwnProperty, se = Array.isArray, I = console.createTask ? console.createTask : function() {
      return null;
    };
    k = {
      "react-stack-bottom-frame": function(e) {
        return e();
      }
    };
    var V, X = {}, F = k["react-stack-bottom-frame"].bind(
      k,
      f
    )(), Q = I(N(f)), L = {};
    ee.Fragment = C, ee.jsx = function(e, n, c, i, b) {
      var m = 1e4 > D.recentlyCreatedOwnerStacks++;
      return z(
        e,
        n,
        c,
        !1,
        i,
        b,
        m ? Error("react-stack-top-frame") : F,
        m ? I(N(e)) : Q
      );
    }, ee.jsxs = function(e, n, c, i, b) {
      var m = 1e4 > D.recentlyCreatedOwnerStacks++;
      return z(
        e,
        n,
        c,
        !0,
        i,
        b,
        m ? Error("react-stack-top-frame") : F,
        m ? I(N(e)) : Q
      );
    };
  }()), ee;
}
var ge;
function be() {
  return ge || (ge = 1, process.env.NODE_ENV === "production" ? ae.exports = ye() : ae.exports = ke()), ae.exports;
}
var r = be();
function Ee(o) {
  return /* @__PURE__ */ r.jsx("div", { children: "This is a dummy component being served from a separate library" });
}
const Ae = je(
  {
    type: "dummy",
    propSchema: {},
    content: "inline"
  },
  {
    render: (o) => /* @__PURE__ */ r.jsx(Ee, {})
  }
), Te = (o) => ({
  title: "Insert Dummy Block",
  onItemClick: () => ve(o, {
    type: "dummy"
  }),
  aliases: ["dummy"],
  group: "Other",
  icon: /* @__PURE__ */ r.jsx("span", { children: "🧩" }),
  subtext: "Used to insert a Dummy block"
}), ie = "#000091", _e = "#FBF5F2", De = "#3a3a3a", we = "https://openproject.local", Se = ({
  block: o,
  editor: P
}) => {
  var U, B, u, S, G, oe, ue, de;
  const [v, N] = p("search"), [d, f] = p(""), [h, x] = p([]), [y, re] = p(null), [z, j] = p(!1), [k, O] = p(-1), T = fe(null), C = fe(null), [ne, J] = p([]), [_, ce] = p(null), [$, W] = p([]), [w, H] = p(null), [A, q] = p([]), [Y, D] = p(null), [M, se] = p(""), [I, V] = p(""), [X, F] = p(!1), [Q, L] = p(null), [e, n] = p(null);
  te.useEffect(() => {
    o.props.wpid && fetch(`api/v3/work_packages/${o.props.wpid}`, {
      method: "GET",
      headers: { "Content-Type": "application/json" }
    }).then(async (t) => {
      if (!t.ok)
        return;
      const s = await t.json();
      re(s);
    }).catch((t) => {
      console.error("Error fetching work package:", t);
    });
  }, [o.props.wpid]), te.useEffect(() => {
    if (!w) {
      q([]), D(null);
      return;
    }
    let t = !0;
    return (async () => {
      var a;
      try {
        const l = await fetch("api/v3/statuses", {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!l.ok)
          throw new Error(`HTTP error! status: ${l.status}`);
        const g = await l.json();
        t && ((a = g._embedded) != null && a.elements) || t && q([]);
      } catch (l) {
        t && q([]), console.error("Error fetching statuses:", l);
      }
    })(), () => {
      t = !1;
    };
  }, [w]), te.useEffect(() => {
    if (!_) {
      W([]), H(null);
      return;
    }
    let t = !0;
    return (async () => {
      var a;
      try {
        const l = await fetch(`api/v3/projects/${_}/types`, {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!l.ok)
          throw new Error(`HTTP error! status: ${l.status}`);
        const g = await l.json();
        t && ((a = g._embedded) != null && a.elements) ? W(
          g._embedded.elements.filter((E) => {
            var R, Z;
            return (Z = (R = E._links) == null ? void 0 : R.self) == null ? void 0 : Z.href;
          })
        ) : t && W([]);
      } catch (l) {
        t && W([]), console.error("Error fetching types:", l);
      }
    })(), () => {
      t = !1;
    };
  }, [_]), te.useEffect(() => {
    if (v !== "create")
      return;
    let t = !0;
    return (async () => {
      var a;
      try {
        const l = await fetch("api/v3/projects", {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!l.ok)
          throw new Error(`HTTP error! status: ${l.status}`);
        const g = await l.json();
        t && ((a = g._embedded) != null && a.elements) ? J(
          g._embedded.elements.map((E) => ({
            id: E.id,
            name: E.name
          }))
        ) : t && J([]);
      } catch (l) {
        t && J([]), console.error("Error fetching projects:", l);
      }
    })(), () => {
      t = !1;
    };
  }, [v]), le(() => {
    const t = (s) => {
      C.current && !C.current.contains(s.target) && T.current && !T.current.contains(s.target) && j(!1);
    };
    return document.addEventListener("mousedown", t), () => {
      document.removeEventListener("mousedown", t);
    };
  }, []);
  const c = xe(async () => {
    if (!d) {
      x([]), j(!1);
      return;
    }
    try {
      const t = await fetch(
        `api/v3/work_packages?filters=[{"typeahead":{"operator":"**","values":["${d}"]}}]`,
        {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        }
      );
      if (!t.ok)
        throw new Error(`HTTP error! status: ${t.status}`);
      const s = await t.json();
      s && s._embedded && s._embedded.elements ? (x(s._embedded.elements), j(s._embedded.elements.length > 0), O(-1)) : (console.error("Invalid API response:", s), x([]), j(!1));
    } catch (t) {
      console.error("Error fetching work packages:", t), x([]), j(!1);
    }
  }, [d]);
  le(() => {
    const t = setTimeout(() => {
      d && c();
    }, 300);
    return () => clearTimeout(t);
  }, [d, c]);
  const i = (t) => {
    var s, a, l, g, E, R, Z, pe;
    re(t), f(""), j(!1), P.updateBlock(o, {
      props: {
        ...o.props,
        wpid: t.id,
        subject: t.subject,
        status: ((a = (s = t._links) == null ? void 0 : s.status) == null ? void 0 : a.title) || "",
        assignee: ((g = (l = t._links) == null ? void 0 : l.assignee) == null ? void 0 : g.title) || "",
        type: ((R = (E = t._links) == null ? void 0 : E.type) == null ? void 0 : R.title) || "",
        href: ((pe = (Z = t._links) == null ? void 0 : Z.self) == null ? void 0 : pe.href) || ""
      }
    });
  };
  le(() => {
    v === "search" && T.current && setTimeout(() => {
      var t;
      return (t = T == null ? void 0 : T.current) == null ? void 0 : t.focus();
    }, 50);
  }, [v]);
  const b = (t) => {
    if (z)
      switch (t.key) {
        case "ArrowDown":
          t.preventDefault(), O((s) => s < h.length - 1 ? s + 1 : s);
          break;
        case "ArrowUp":
          t.preventDefault(), O((s) => s > 0 ? s - 1 : 0);
          break;
        case "Enter":
          t.preventDefault(), k >= 0 && k < h.length && i(h[k]);
          break;
        case "Escape":
          t.preventDefault(), j(!1);
          break;
      }
  }, m = `${we}/wp/${o.props.wpid}`;
  return /* @__PURE__ */ r.jsxs(
    "div",
    {
      style: {
        padding: "12px 10px",
        border: "none",
        borderRadius: "5px",
        backgroundColor: _e,
        width: "450px"
      },
      children: [
        v === "search" && /* @__PURE__ */ r.jsxs("div", { children: [
          !o.props.wpid && /* @__PURE__ */ r.jsxs("div", { style: { position: "relative" }, children: [
            /* @__PURE__ */ r.jsx(
              "div",
              {
                style: {
                  display: "flex"
                },
                children: /* @__PURE__ */ r.jsx(
                  "input",
                  {
                    ref: T,
                    type: "text",
                    placeholder: "Search for work package ID or subject",
                    value: d,
                    onChange: (t) => {
                      f(t.target.value), t.target.value && j(!0);
                    },
                    onFocus: () => {
                      h.length > 0 && j(!0);
                    },
                    onKeyDown: b,
                    style: {
                      width: "100%",
                      padding: "8px 12px",
                      borderRadius: "4px",
                      border: "1px solid #ccc",
                      fontSize: "14px"
                    }
                  }
                )
              }
            ),
            z && h.length > 0 && /* @__PURE__ */ r.jsx(
              "div",
              {
                ref: C,
                role: "listbox",
                "aria-label": "Work package search results",
                style: {
                  position: "absolute",
                  top: "100%",
                  left: 0,
                  right: 0,
                  zIndex: 10,
                  backgroundColor: "white",
                  border: "1px solid #ccc",
                  borderRadius: "0 0 4px 4px",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                  maxHeight: "200px",
                  overflowY: "auto",
                  marginTop: "2px"
                },
                children: h.slice(0, 5).map((t, s) => {
                  var a, l, g, E;
                  return /* @__PURE__ */ r.jsxs(
                    "div",
                    {
                      role: "option",
                      "aria-selected": k === s,
                      tabIndex: 0,
                      onClick: () => i(t),
                      onKeyDown: (R) => {
                        (R.key === "Enter" || R.key === " ") && (R.preventDefault(), i(t));
                      },
                      onMouseEnter: () => O(s),
                      style: {
                        padding: "8px 12px",
                        cursor: "pointer",
                        backgroundColor: k === s ? "#f0f0f0" : "transparent",
                        borderBottom: s < h.length - 1 ? "1px solid #eee" : "none"
                      },
                      children: [
                        /* @__PURE__ */ r.jsxs("div", { style: { fontWeight: "bold" }, children: [
                          "#",
                          t.id,
                          " - ",
                          t.subject
                        ] }),
                        /* @__PURE__ */ r.jsxs("div", { style: { fontSize: "12px", color: "#666" }, children: [
                          (l = (a = t._links) == null ? void 0 : a.type) == null ? void 0 : l.title,
                          " ",
                          (E = (g = t._links) == null ? void 0 : g.status) == null ? void 0 : E.title
                        ] })
                      ]
                    },
                    t.id
                  );
                })
              }
            )
          ] }),
          o.props.wpid && !y && /* @__PURE__ */ r.jsxs("div", { children: [
            "#",
            o.props.wpid,
            " ",
            o.props.subject
          ] }),
          y && /* @__PURE__ */ r.jsxs("div", { children: [
            /* @__PURE__ */ r.jsxs(
              "div",
              {
                style: {
                  display: "flex",
                  gap: "8px"
                },
                children: [
                  /* @__PURE__ */ r.jsx(
                    "div",
                    {
                      style: {
                        gap: "8px",
                        color: ((B = (U = y._embedded) == null ? void 0 : U.type) == null ? void 0 : B.color) || ie,
                        fontWeight: "bold",
                        textTransform: "uppercase"
                      },
                      children: (S = (u = y._links) == null ? void 0 : u.type) == null ? void 0 : S.title
                    }
                  ),
                  /* @__PURE__ */ r.jsxs(
                    "div",
                    {
                      style: {
                        color: "#666"
                      },
                      children: [
                        "#",
                        y.id
                      ]
                    }
                  ),
                  /* @__PURE__ */ r.jsx(
                    "div",
                    {
                      style: {
                        fontSize: "0.8rem",
                        borderRadius: "12px",
                        padding: "2px 8px",
                        border: "1px solid #ccc",
                        backgroundColor: ((oe = (G = y._embedded) == null ? void 0 : G.status) == null ? void 0 : oe.color) || ie
                      },
                      children: (de = (ue = y._links) == null ? void 0 : ue.status) == null ? void 0 : de.title
                    }
                  )
                ]
              }
            ),
            /* @__PURE__ */ r.jsx("div", { children: /* @__PURE__ */ r.jsx(
              "a",
              {
                href: m,
                style: {
                  marginRight: 6,
                  textDecoration: "none",
                  color: ie,
                  cursor: "pointer"
                },
                onClick: (t) => {
                  t.preventDefault(), t.stopPropagation(), window.open(m, "_blank");
                },
                onMouseOver: (t) => t.currentTarget.style.textDecoration = "underline",
                onMouseOut: (t) => t.currentTarget.style.textDecoration = "none",
                children: y.subject
              }
            ) })
          ] })
        ] }),
        v === "create" && /* @__PURE__ */ r.jsxs("div", { children: [
          /* @__PURE__ */ r.jsx("p", { children: "Select a project to create a new work package in:" }),
          ne.length === 0 ? /* @__PURE__ */ r.jsx("p", { children: "Loading projects..." }) : /* @__PURE__ */ r.jsxs("select", { value: _ || "", onChange: (t) => ce(t.target.value), children: [
            /* @__PURE__ */ r.jsx("option", { value: "", children: "Select a project" }),
            ne.map((t) => /* @__PURE__ */ r.jsx("option", { value: t.id, children: t.name }, t.id))
          ] }),
          _ && /* @__PURE__ */ r.jsxs("div", { style: { marginTop: 16 }, children: [
            /* @__PURE__ */ r.jsx("p", { children: "Select a work package type:" }),
            $.length === 0 ? /* @__PURE__ */ r.jsx("p", { children: "Loading types..." }) : /* @__PURE__ */ r.jsxs("select", { value: w || "", onChange: (t) => H(t.target.value), children: [
              /* @__PURE__ */ r.jsx("option", { value: "", children: "Select a type" }),
              $.map((t) => /* @__PURE__ */ r.jsx("option", { value: t.id, children: t.name }, t.id))
            ] })
          ] }),
          w && /* @__PURE__ */ r.jsxs("div", { style: { marginTop: 16 }, children: [
            /* @__PURE__ */ r.jsx("p", { children: "Enter work package details:" }),
            /* @__PURE__ */ r.jsx("div", { style: { marginBottom: 8 }, children: /* @__PURE__ */ r.jsxs("label", { children: [
              "Status",
              ":",
              " ",
              A.length === 0 ? /* @__PURE__ */ r.jsx("span", { children: "Loading statuses..." }) : /* @__PURE__ */ r.jsxs("select", { value: Y || "", onChange: (t) => D(t.target.value), children: [
                /* @__PURE__ */ r.jsx("option", { value: "", children: "Select a status" }),
                A.map((t) => /* @__PURE__ */ r.jsx("option", { value: t.id, children: t.name }, t.id))
              ] })
            ] }) }),
            /* @__PURE__ */ r.jsx("div", { style: { marginBottom: 8 }, children: /* @__PURE__ */ r.jsxs("label", { children: [
              "Subject",
              ": ",
              /* @__PURE__ */ r.jsx("input", { type: "text", value: M, onChange: (t) => se(t.target.value) })
            ] }) }),
            /* @__PURE__ */ r.jsx("div", { style: { marginBottom: 8 }, children: /* @__PURE__ */ r.jsxs("label", { children: [
              "Description",
              ": ",
              /* @__PURE__ */ r.jsx("textarea", { value: I, onChange: (t) => V(t.target.value) })
            ] }) }),
            /* @__PURE__ */ r.jsxs("div", { children: [
              /* @__PURE__ */ r.jsx(
                "button",
                {
                  disabled: X || !M || !I || !Y || !w || !_,
                  onClick: () => {
                    L(null), n(null), F(!0);
                    const t = $.find((a) => a.id === w), s = A.find((a) => a.id === Y);
                    if (console.log("types:", $), console.log("statuses:", A), console.log("selectedType:", w), console.log("selectedStatus:", Y), console.log("typeObj:", t), console.log("statusObj:", s), !t || !s) {
                      L("Type or status not found."), F(!1);
                      return;
                    }
                    fetch(`api/v3/projects/${_}/work_packages`, {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({
                        subject: M,
                        description: { format: "plain", raw: I },
                        _links: {
                          type: { href: t._links.self.href },
                          status: { href: s._links.self.href }
                        }
                      })
                    }).then(async (a) => {
                      if (!a.ok) {
                        const l = await a.text();
                        throw new Error(`HTTP error! status: ${a.status} - ${l}`);
                      }
                      n("Work package created successfully!"), se(""), V(""), D(null), H(null);
                    }).catch((a) => {
                      console.error("Error creating work package:", a), L(
                        "Failed to create work package: " + ((a == null ? void 0 : a.message) || String(a))
                      );
                    }).finally(() => {
                      F(!1);
                    });
                  },
                  children: X ? "Saving..." : "Save"
                }
              ),
              Q && /* @__PURE__ */ r.jsx("div", { style: { color: "red", marginTop: 8 }, children: Q }),
              e && /* @__PURE__ */ r.jsx("div", { style: { color: "green", marginTop: 8 }, children: e })
            ] })
          ] })
        ] })
      ]
    }
  );
}, Ie = je(
  {
    type: "openProjectWorkPackage",
    propSchema: {
      wpid: { default: "", type: "string" },
      subject: { default: "", type: "string" },
      status: { default: "", type: "string" },
      assignee: { default: "", type: "string" },
      type: { default: "", type: "string" },
      href: { default: "", type: "string" }
    },
    content: "inline"
  },
  {
    render: ({ block: o, editor: P }) => /* @__PURE__ */ r.jsx(Se, { block: o, editor: P })
  }
), Re = (o) => ({
  title: "Open Project Work Package",
  onItemClick: () => ve(o, {
    type: "openProjectWorkPackage"
  }),
  aliases: ["openproject", "workpackage", "op", "wp"],
  group: "OpenProject",
  icon: /* @__PURE__ */ r.jsx("span", { children: "📦" }),
  subtext: "Search and link an existing Work Package"
});
function Ne(o) {
  return [
    Re(o),
    Te(o)
  ];
}
export {
  Ee as DummyComponent,
  we as OPENPROJECT_HOST,
  _e as UI_BEIGE,
  ie as UI_BLUE,
  De as UI_GRAY,
  Ae as dummyBlockSpec,
  Te as dummySlashMenu,
  Ne as getDefaultOpenProjectSlashMenuItems,
  Ie as openProjectWorkPackageBlockSpec,
  Re as openProjectWorkPackageSlashMenu
};
