import te, { useState as p, useRef as fe, useEffect as le, useCallback as xe } from "react";
import { createReactBlockSpec as ge } from "@blocknote/react";
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
function je() {
  if (he) return K;
  he = 1;
  var l = Symbol.for("react.transitional.element"), O = Symbol.for("react.fragment");
  function g(I, d, f) {
    var h = null;
    if (f !== void 0 && (h = "" + f), d.key !== void 0 && (h = "" + d.key), "key" in d) {
      f = {};
      for (var j in d)
        j !== "key" && (f[j] = d[j]);
    } else f = d;
    return d = f.ref, {
      $$typeof: l,
      type: I,
      key: h,
      ref: d !== void 0 ? d : null,
      props: f
    };
  }
  return K.Fragment = O, K.jsx = g, K.jsxs = g, K;
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
function ye() {
  return me || (me = 1, process.env.NODE_ENV !== "production" && function() {
    function l(e) {
      if (e == null) return null;
      if (typeof e == "function")
        return e.$$typeof === W ? null : e.displayName || e.name || null;
      if (typeof e == "string") return e;
      switch (e) {
        case C:
          return "Fragment";
        case J:
          return "Profiler";
        case ne:
          return "StrictMode";
        case Y:
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
            return n = e.displayName || null, n !== null ? n : l(e.type) || "Memo";
          case A:
            n = e._payload, e = e._init;
            try {
              return l(e(n));
            } catch {
            }
        }
      return null;
    }
    function O(e) {
      return "" + e;
    }
    function g(e) {
      try {
        O(e);
        var n = !1;
      } catch {
        n = !0;
      }
      if (n) {
        n = console;
        var a = n.error, i = typeof Symbol == "function" && Symbol.toStringTag && e[Symbol.toStringTag] || e.constructor.name || "Object";
        return a.call(
          n,
          "The provided key is an unsupported type %s. This value must be coerced to a string before using it here.",
          i
        ), O(e);
      }
    }
    function I(e) {
      if (e === C) return "<>";
      if (typeof e == "object" && e !== null && e.$$typeof === A)
        return "<...>";
      try {
        var n = l(e);
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
      if (F.call(e, "key")) {
        var n = Object.getOwnPropertyDescriptor(e, "key").get;
        if (n && n.isReactWarning) return !1;
      }
      return e.key !== void 0;
    }
    function j(e, n) {
      function a() {
        V || (V = !0, console.error(
          "%s: `key` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://react.dev/link/special-props)",
          n
        ));
      }
      a.isReactWarning = !0, Object.defineProperty(e, "key", {
        get: a,
        configurable: !0
      });
    }
    function y() {
      var e = l(this.type);
      return X[e] || (X[e] = !0, console.error(
        "Accessing element.ref was removed in React 19. ref is now a regular prop. It will be removed from the JSX Element type in a future release."
      )), e = this.props.ref, e !== void 0 ? e : null;
    }
    function re(e, n, a, i, E, m, U, B) {
      return a = m.ref, e = {
        $$typeof: P,
        type: e,
        key: n,
        props: m,
        _owner: E
      }, (a !== void 0 ? a : null) !== null ? Object.defineProperty(e, "ref", {
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
    function z(e, n, a, i, E, m, U, B) {
      var u = n.children;
      if (u !== void 0)
        if (i)
          if (se(u)) {
            for (i = 0; i < u.length; i++)
              x(u[i]);
            Object.freeze && Object.freeze(u);
          } else
            console.error(
              "React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead."
            );
        else x(u);
      if (F.call(n, "key")) {
        u = l(e);
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
      if (u = null, a !== void 0 && (g(a), u = "" + a), h(n) && (g(n.key), u = "" + n.key), "key" in n) {
        a = {};
        for (var G in n)
          G !== "key" && (a[G] = n[G]);
      } else a = n;
      return u && j(
        a,
        typeof e == "function" ? e.displayName || e.name || "Unknown" : e
      ), re(
        e,
        u,
        m,
        E,
        d(),
        a,
        U,
        B
      );
    }
    function x(e) {
      typeof e == "object" && e !== null && e.$$typeof === P && e._store && (e._store.validated = 1);
    }
    var b = te, P = Symbol.for("react.transitional.element"), T = Symbol.for("react.portal"), C = Symbol.for("react.fragment"), ne = Symbol.for("react.strict_mode"), J = Symbol.for("react.profiler"), _ = Symbol.for("react.consumer"), ce = Symbol.for("react.context"), $ = Symbol.for("react.forward_ref"), Y = Symbol.for("react.suspense"), w = Symbol.for("react.suspense_list"), H = Symbol.for("react.memo"), A = Symbol.for("react.lazy"), q = Symbol.for("react.activity"), W = Symbol.for("react.client.reference"), D = b.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE, F = Object.prototype.hasOwnProperty, se = Array.isArray, N = console.createTask ? console.createTask : function() {
      return null;
    };
    b = {
      "react-stack-bottom-frame": function(e) {
        return e();
      }
    };
    var V, X = {}, M = b["react-stack-bottom-frame"].bind(
      b,
      f
    )(), Q = N(I(f)), L = {};
    ee.Fragment = C, ee.jsx = function(e, n, a, i, E) {
      var m = 1e4 > D.recentlyCreatedOwnerStacks++;
      return z(
        e,
        n,
        a,
        !1,
        i,
        E,
        m ? Error("react-stack-top-frame") : M,
        m ? N(I(e)) : Q
      );
    }, ee.jsxs = function(e, n, a, i, E) {
      var m = 1e4 > D.recentlyCreatedOwnerStacks++;
      return z(
        e,
        n,
        a,
        !0,
        i,
        E,
        m ? Error("react-stack-top-frame") : M,
        m ? N(I(e)) : Q
      );
    };
  }()), ee;
}
var ve;
function be() {
  return ve || (ve = 1, process.env.NODE_ENV === "production" ? ae.exports = je() : ae.exports = ye()), ae.exports;
}
var r = be();
function Ee(l) {
  return /* @__PURE__ */ r.jsx("div", { children: "This is a dummy component being served from a separate library" });
}
const Re = ge(
  {
    type: "dummy",
    propSchema: {},
    content: "inline"
  },
  {
    render: (l) => /* @__PURE__ */ r.jsx(Ee, {})
  }
), ie = "#000091", ke = "#FBF5F2", Oe = "#3a3a3a", Te = "https://openproject.local", _e = ({
  block: l,
  editor: O
}) => {
  var U, B, u, S, G, oe, ue, de;
  const [g, I] = p("search"), [d, f] = p(""), [h, j] = p([]), [y, re] = p(null), [z, x] = p(!1), [b, P] = p(-1), T = fe(null), C = fe(null), [ne, J] = p([]), [_, ce] = p(null), [$, Y] = p([]), [w, H] = p(null), [A, q] = p([]), [W, D] = p(null), [F, se] = p(""), [N, V] = p(""), [X, M] = p(!1), [Q, L] = p(null), [e, n] = p(null);
  te.useEffect(() => {
    l.props.wpid && fetch(`api/v3/work_packages/${l.props.wpid}`, {
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
  }, [l.props.wpid]), te.useEffect(() => {
    if (!w) {
      q([]), D(null);
      return;
    }
    let t = !0;
    return (async () => {
      var o;
      try {
        const c = await fetch("api/v3/statuses", {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!c.ok)
          throw new Error(`HTTP error! status: ${c.status}`);
        const v = await c.json();
        t && ((o = v._embedded) != null && o.elements) || t && q([]);
      } catch (c) {
        t && q([]), console.error("Error fetching statuses:", c);
      }
    })(), () => {
      t = !1;
    };
  }, [w]), te.useEffect(() => {
    if (!_) {
      Y([]), H(null);
      return;
    }
    let t = !0;
    return (async () => {
      var o;
      try {
        const c = await fetch(`api/v3/projects/${_}/types`, {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!c.ok)
          throw new Error(`HTTP error! status: ${c.status}`);
        const v = await c.json();
        t && ((o = v._embedded) != null && o.elements) ? Y(
          v._embedded.elements.filter((k) => {
            var R, Z;
            return (Z = (R = k._links) == null ? void 0 : R.self) == null ? void 0 : Z.href;
          })
        ) : t && Y([]);
      } catch (c) {
        t && Y([]), console.error("Error fetching types:", c);
      }
    })(), () => {
      t = !1;
    };
  }, [_]), te.useEffect(() => {
    if (g !== "create")
      return;
    let t = !0;
    return (async () => {
      var o;
      try {
        const c = await fetch("api/v3/projects", {
          method: "GET",
          headers: { "Content-Type": "application/json" }
        });
        if (!c.ok)
          throw new Error(`HTTP error! status: ${c.status}`);
        const v = await c.json();
        t && ((o = v._embedded) != null && o.elements) ? J(
          v._embedded.elements.map((k) => ({
            id: k.id,
            name: k.name
          }))
        ) : t && J([]);
      } catch (c) {
        t && J([]), console.error("Error fetching projects:", c);
      }
    })(), () => {
      t = !1;
    };
  }, [g]), le(() => {
    const t = (s) => {
      C.current && !C.current.contains(s.target) && T.current && !T.current.contains(s.target) && x(!1);
    };
    return document.addEventListener("mousedown", t), () => {
      document.removeEventListener("mousedown", t);
    };
  }, []);
  const a = xe(async () => {
    if (!d) {
      j([]), x(!1);
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
      s && s._embedded && s._embedded.elements ? (j(s._embedded.elements), x(s._embedded.elements.length > 0), P(-1)) : (console.error("Invalid API response:", s), j([]), x(!1));
    } catch (t) {
      console.error("Error fetching work packages:", t), j([]), x(!1);
    }
  }, [d]);
  le(() => {
    const t = setTimeout(() => {
      d && a();
    }, 300);
    return () => clearTimeout(t);
  }, [d, a]);
  const i = (t) => {
    var s, o, c, v, k, R, Z, pe;
    re(t), f(""), x(!1), O.updateBlock(l, {
      props: {
        ...l.props,
        wpid: t.id,
        subject: t.subject,
        status: ((o = (s = t._links) == null ? void 0 : s.status) == null ? void 0 : o.title) || "",
        assignee: ((v = (c = t._links) == null ? void 0 : c.assignee) == null ? void 0 : v.title) || "",
        type: ((R = (k = t._links) == null ? void 0 : k.type) == null ? void 0 : R.title) || "",
        href: ((pe = (Z = t._links) == null ? void 0 : Z.self) == null ? void 0 : pe.href) || ""
      }
    });
  };
  le(() => {
    g === "search" && T.current && setTimeout(() => {
      var t;
      return (t = T == null ? void 0 : T.current) == null ? void 0 : t.focus();
    }, 50);
  }, [g]);
  const E = (t) => {
    if (z)
      switch (t.key) {
        case "ArrowDown":
          t.preventDefault(), P((s) => s < h.length - 1 ? s + 1 : s);
          break;
        case "ArrowUp":
          t.preventDefault(), P((s) => s > 0 ? s - 1 : 0);
          break;
        case "Enter":
          t.preventDefault(), b >= 0 && b < h.length && i(h[b]);
          break;
        case "Escape":
          t.preventDefault(), x(!1);
          break;
      }
  }, m = `${Te}/wp/${l.props.wpid}`;
  return /* @__PURE__ */ r.jsxs(
    "div",
    {
      style: {
        padding: "12px 10px",
        border: "none",
        borderRadius: "5px",
        backgroundColor: ke,
        width: "450px"
      },
      children: [
        g === "search" && /* @__PURE__ */ r.jsxs("div", { children: [
          !l.props.wpid && /* @__PURE__ */ r.jsxs("div", { style: { position: "relative" }, children: [
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
                      f(t.target.value), t.target.value && x(!0);
                    },
                    onFocus: () => {
                      h.length > 0 && x(!0);
                    },
                    onKeyDown: E,
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
                  var o, c, v, k;
                  return /* @__PURE__ */ r.jsxs(
                    "div",
                    {
                      role: "option",
                      "aria-selected": b === s,
                      tabIndex: 0,
                      onClick: () => i(t),
                      onKeyDown: (R) => {
                        (R.key === "Enter" || R.key === " ") && (R.preventDefault(), i(t));
                      },
                      onMouseEnter: () => P(s),
                      style: {
                        padding: "8px 12px",
                        cursor: "pointer",
                        backgroundColor: b === s ? "#f0f0f0" : "transparent",
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
                          (c = (o = t._links) == null ? void 0 : o.type) == null ? void 0 : c.title,
                          " ",
                          (k = (v = t._links) == null ? void 0 : v.status) == null ? void 0 : k.title
                        ] })
                      ]
                    },
                    t.id
                  );
                })
              }
            )
          ] }),
          l.props.wpid && !y && /* @__PURE__ */ r.jsxs("div", { children: [
            "#",
            l.props.wpid,
            " ",
            l.props.subject
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
        g === "create" && /* @__PURE__ */ r.jsxs("div", { children: [
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
              A.length === 0 ? /* @__PURE__ */ r.jsx("span", { children: "Loading statuses..." }) : /* @__PURE__ */ r.jsxs("select", { value: W || "", onChange: (t) => D(t.target.value), children: [
                /* @__PURE__ */ r.jsx("option", { value: "", children: "Select a status" }),
                A.map((t) => /* @__PURE__ */ r.jsx("option", { value: t.id, children: t.name }, t.id))
              ] })
            ] }) }),
            /* @__PURE__ */ r.jsx("div", { style: { marginBottom: 8 }, children: /* @__PURE__ */ r.jsxs("label", { children: [
              "Subject",
              ": ",
              /* @__PURE__ */ r.jsx("input", { type: "text", value: F, onChange: (t) => se(t.target.value) })
            ] }) }),
            /* @__PURE__ */ r.jsx("div", { style: { marginBottom: 8 }, children: /* @__PURE__ */ r.jsxs("label", { children: [
              "Description",
              ": ",
              /* @__PURE__ */ r.jsx("textarea", { value: N, onChange: (t) => V(t.target.value) })
            ] }) }),
            /* @__PURE__ */ r.jsxs("div", { children: [
              /* @__PURE__ */ r.jsx(
                "button",
                {
                  disabled: X || !F || !N || !W || !w || !_,
                  onClick: () => {
                    L(null), n(null), M(!0);
                    const t = $.find((o) => o.id === w), s = A.find((o) => o.id === W);
                    if (console.log("types:", $), console.log("statuses:", A), console.log("selectedType:", w), console.log("selectedStatus:", W), console.log("typeObj:", t), console.log("statusObj:", s), !t || !s) {
                      L("Type or status not found."), M(!1);
                      return;
                    }
                    fetch(`api/v3/projects/${_}/work_packages`, {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({
                        subject: F,
                        description: { format: "plain", raw: N },
                        _links: {
                          type: { href: t._links.self.href },
                          status: { href: s._links.self.href }
                        }
                      })
                    }).then(async (o) => {
                      if (!o.ok) {
                        const c = await o.text();
                        throw new Error(`HTTP error! status: ${o.status} - ${c}`);
                      }
                      n("Work package created successfully!"), se(""), V(""), D(null), H(null);
                    }).catch((o) => {
                      console.error("Error creating work package:", o), L(
                        "Failed to create work package: " + ((o == null ? void 0 : o.message) || String(o))
                      );
                    }).finally(() => {
                      M(!1);
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
}, Pe = ge(
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
    render: ({ block: l, editor: O }) => /* @__PURE__ */ r.jsx(_e, { block: l, editor: O })
  }
);
export {
  Ee as DummyComponent,
  Te as OPENPROJECT_HOST,
  ke as UI_BEIGE,
  ie as UI_BLUE,
  Oe as UI_GRAY,
  Re as dummyBlockSpec,
  Pe as openProjectWorkPackageBlockSpec
};
