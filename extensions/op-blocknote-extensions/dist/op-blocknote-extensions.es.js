import re from "react";
import { createReactBlockSpec as te } from "@blocknote/react";
var v = { exports: {} }, R = {};
/**
 * @license React
 * react-jsx-runtime.production.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var $;
function ne() {
  if ($) return R;
  $ = 1;
  var c = Symbol.for("react.transitional.element"), p = Symbol.for("react.fragment");
  function f(m, a, s) {
    var d = null;
    if (s !== void 0 && (d = "" + s), a.key !== void 0 && (d = "" + a.key), "key" in a) {
      s = {};
      for (var E in a)
        E !== "key" && (s[E] = a[E]);
    } else s = a;
    return a = s.ref, {
      $$typeof: c,
      type: m,
      key: d,
      ref: a !== void 0 ? a : null,
      props: s
    };
  }
  return R.Fragment = p, R.jsx = f, R.jsxs = f, R;
}
var b = {};
/**
 * @license React
 * react-jsx-runtime.development.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var D;
function oe() {
  return D || (D = 1, process.env.NODE_ENV !== "production" && function() {
    function c(e) {
      if (e == null) return null;
      if (typeof e == "function")
        return e.$$typeof === Q ? null : e.displayName || e.name || null;
      if (typeof e == "string") return e;
      switch (e) {
        case T:
          return "Fragment";
        case J:
          return "Profiler";
        case q:
          return "StrictMode";
        case X:
          return "Suspense";
        case B:
          return "SuspenseList";
        case Z:
          return "Activity";
      }
      if (typeof e == "object")
        switch (typeof e.tag == "number" && console.error(
          "Received an unexpected object in getComponentNameFromType(). This is likely a bug in React. Please file an issue."
        ), e.$$typeof) {
          case U:
            return "Portal";
          case V:
            return (e.displayName || "Context") + ".Provider";
          case z:
            return (e._context.displayName || "Context") + ".Consumer";
          case G:
            var r = e.render;
            return e = e.displayName, e || (e = r.displayName || r.name || "", e = e !== "" ? "ForwardRef(" + e + ")" : "ForwardRef"), e;
          case H:
            return r = e.displayName || null, r !== null ? r : c(e.type) || "Memo";
          case y:
            r = e._payload, e = e._init;
            try {
              return c(e(r));
            } catch {
            }
        }
      return null;
    }
    function p(e) {
      return "" + e;
    }
    function f(e) {
      try {
        p(e);
        var r = !1;
      } catch {
        r = !0;
      }
      if (r) {
        r = console;
        var t = r.error, n = typeof Symbol == "function" && Symbol.toStringTag && e[Symbol.toStringTag] || e.constructor.name || "Object";
        return t.call(
          r,
          "The provided key is an unsupported type %s. This value must be coerced to a string before using it here.",
          n
        ), p(e);
      }
    }
    function m(e) {
      if (e === T) return "<>";
      if (typeof e == "object" && e !== null && e.$$typeof === y)
        return "<...>";
      try {
        var r = c(e);
        return r ? "<" + r + ">" : "<...>";
      } catch {
        return "<...>";
      }
    }
    function a() {
      var e = k.A;
      return e === null ? null : e.getOwner();
    }
    function s() {
      return Error("react-stack-top-frame");
    }
    function d(e) {
      if (h.call(e, "key")) {
        var r = Object.getOwnPropertyDescriptor(e, "key").get;
        if (r && r.isReactWarning) return !1;
      }
      return e.key !== void 0;
    }
    function E(e, r) {
      function t() {
        g || (g = !0, console.error(
          "%s: `key` is not a prop. Trying to access it will result in `undefined` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://react.dev/link/special-props)",
          r
        ));
      }
      t.isReactWarning = !0, Object.defineProperty(e, "key", {
        get: t,
        configurable: !0
      });
    }
    function M() {
      var e = c(this.type);
      return N[e] || (N[e] = !0, console.error(
        "Accessing element.ref was removed in React 19. ref is now a regular prop. It will be removed from the JSX Element type in a future release."
      )), e = this.props.ref, e !== void 0 ? e : null;
    }
    function W(e, r, t, n, l, u, S, A) {
      return t = u.ref, e = {
        $$typeof: w,
        type: e,
        key: r,
        props: u,
        _owner: l
      }, (t !== void 0 ? t : null) !== null ? Object.defineProperty(e, "ref", {
        enumerable: !1,
        get: M
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
        value: S
      }), Object.defineProperty(e, "_debugTask", {
        configurable: !1,
        enumerable: !1,
        writable: !0,
        value: A
      }), Object.freeze && (Object.freeze(e.props), Object.freeze(e)), e;
    }
    function j(e, r, t, n, l, u, S, A) {
      var o = r.children;
      if (o !== void 0)
        if (n)
          if (K(o)) {
            for (n = 0; n < o.length; n++)
              x(o[n]);
            Object.freeze && Object.freeze(o);
          } else
            console.error(
              "React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead."
            );
        else x(o);
      if (h.call(r, "key")) {
        o = c(e);
        var i = Object.keys(r).filter(function(ee) {
          return ee !== "key";
        });
        n = 0 < i.length ? "{key: someKey, " + i.join(": ..., ") + ": ...}" : "{key: someKey}", I[o + n] || (i = 0 < i.length ? "{" + i.join(": ..., ") + ": ...}" : "{}", console.error(
          `A props object containing a "key" prop is being spread into JSX:
  let props = %s;
  <%s {...props} />
React keys must be passed directly to JSX without using spread:
  let props = %s;
  <%s key={someKey} {...props} />`,
          n,
          o,
          i,
          o
        ), I[o + n] = !0);
      }
      if (o = null, t !== void 0 && (f(t), o = "" + t), d(r) && (f(r.key), o = "" + r.key), "key" in r) {
        t = {};
        for (var P in r)
          P !== "key" && (t[P] = r[P]);
      } else t = r;
      return o && E(
        t,
        typeof e == "function" ? e.displayName || e.name || "Unknown" : e
      ), W(
        e,
        o,
        u,
        l,
        a(),
        t,
        S,
        A
      );
    }
    function x(e) {
      typeof e == "object" && e !== null && e.$$typeof === w && e._store && (e._store.validated = 1);
    }
    var _ = re, w = Symbol.for("react.transitional.element"), U = Symbol.for("react.portal"), T = Symbol.for("react.fragment"), q = Symbol.for("react.strict_mode"), J = Symbol.for("react.profiler"), z = Symbol.for("react.consumer"), V = Symbol.for("react.context"), G = Symbol.for("react.forward_ref"), X = Symbol.for("react.suspense"), B = Symbol.for("react.suspense_list"), H = Symbol.for("react.memo"), y = Symbol.for("react.lazy"), Z = Symbol.for("react.activity"), Q = Symbol.for("react.client.reference"), k = _.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE, h = Object.prototype.hasOwnProperty, K = Array.isArray, O = console.createTask ? console.createTask : function() {
      return null;
    };
    _ = {
      "react-stack-bottom-frame": function(e) {
        return e();
      }
    };
    var g, N = {}, C = _["react-stack-bottom-frame"].bind(
      _,
      s
    )(), Y = O(m(s)), I = {};
    b.Fragment = T, b.jsx = function(e, r, t, n, l) {
      var u = 1e4 > k.recentlyCreatedOwnerStacks++;
      return j(
        e,
        r,
        t,
        !1,
        n,
        l,
        u ? Error("react-stack-top-frame") : C,
        u ? O(m(e)) : Y
      );
    }, b.jsxs = function(e, r, t, n, l) {
      var u = 1e4 > k.recentlyCreatedOwnerStacks++;
      return j(
        e,
        r,
        t,
        !0,
        n,
        l,
        u ? Error("react-stack-top-frame") : C,
        u ? O(m(e)) : Y
      );
    };
  }()), b;
}
var F;
function ae() {
  return F || (F = 1, process.env.NODE_ENV === "production" ? v.exports = ne() : v.exports = oe()), v.exports;
}
var L = ae();
function se() {
  return /* @__PURE__ */ L.jsx("div", { children: "This is a dummy component being served from a separate library" });
}
const le = te(
  {
    type: "dummy",
    propSchema: {},
    content: "inline"
  },
  {
    render: (c) => /* @__PURE__ */ L.jsx(se, {})
  }
);
export {
  se as DummyComponent,
  le as dummyBlockSpec
};
