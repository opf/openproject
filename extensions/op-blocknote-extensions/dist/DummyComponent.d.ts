export declare function DummyComponent(_props: any): import("react/jsx-runtime").JSX.Element;
export declare const dummyBlockSpec: {
    config: {
        readonly type: "dummy";
        readonly propSchema: {};
        readonly content: "inline";
    };
    implementation: import("@blocknote/core").TiptapBlockImplementation<{
        readonly type: "dummy";
        readonly propSchema: {};
        readonly content: "inline";
    }, any, import("@blocknote/core").InlineContentSchema, import("@blocknote/core").StyleSchema>;
};
export declare const dummySlashMenu: (editor: any) => {
    title: string;
    onItemClick: () => import("@blocknote/core").Block<Record<string, import("@blocknote/core").BlockConfig>, import("@blocknote/core").InlineContentSchema, import("@blocknote/core").StyleSchema>;
    aliases: string[];
    group: string;
    icon: import("react/jsx-runtime").JSX.Element;
    subtext: string;
};
//# sourceMappingURL=DummyComponent.d.ts.map