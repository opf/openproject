export declare const UI_BLUE = "#000091";
export declare const UI_BEIGE = "#FBF5F2";
export declare const UI_GRAY = "#3a3a3a";
export declare const OPENPROJECT_HOST = "https://openproject.local";
export interface WorkPackage {
    id: string;
    subject: string;
    status?: string | null;
    assignee?: string | null;
    href?: string | null;
    lockVersion?: number | null;
    _links?: {
        self: {
            href: string;
        };
        status: {
            title: string;
            href: string;
        } | null;
        assignee: {
            title: string;
            href: string;
        } | null;
        type: {
            title: string;
            href: string;
        } | null;
    } | null;
    _embedded?: {
        status?: Status | null;
        type?: {
            color: string;
        } | null;
    } | null;
}
export interface WorkPackageCollection {
    _embedded: {
        elements: WorkPackage[];
    };
}
export interface Status {
    id: string;
    name: string;
    isClosed: boolean;
    color: string;
    _links: {
        self: {
            href: string;
        };
    };
}
export declare const openProjectWorkPackageBlockSpec: {
    config: {
        readonly type: "openProjectWorkPackage";
        readonly propSchema: {
            readonly wpid: {
                readonly default: "";
                readonly type: "string";
            };
            readonly subject: {
                readonly default: "";
                readonly type: "string";
            };
            readonly status: {
                readonly default: "";
                readonly type: "string";
            };
            readonly assignee: {
                readonly default: "";
                readonly type: "string";
            };
            readonly type: {
                readonly default: "";
                readonly type: "string";
            };
            readonly href: {
                readonly default: "";
                readonly type: "string";
            };
        };
        readonly content: "inline";
    };
    implementation: import("@blocknote/core").TiptapBlockImplementation<{
        readonly type: "openProjectWorkPackage";
        readonly propSchema: {
            readonly wpid: {
                readonly default: "";
                readonly type: "string";
            };
            readonly subject: {
                readonly default: "";
                readonly type: "string";
            };
            readonly status: {
                readonly default: "";
                readonly type: "string";
            };
            readonly assignee: {
                readonly default: "";
                readonly type: "string";
            };
            readonly type: {
                readonly default: "";
                readonly type: "string";
            };
            readonly href: {
                readonly default: "";
                readonly type: "string";
            };
        };
        readonly content: "inline";
    }, any, import("@blocknote/core").InlineContentSchema, import("@blocknote/core").StyleSchema>;
};
export declare const openProjectWorkPackageSlashMenu: (editor: any) => {
    title: string;
    onItemClick: () => import("@blocknote/core").Block<Record<string, import("@blocknote/core").BlockConfig>, import("@blocknote/core").InlineContentSchema, import("@blocknote/core").StyleSchema>;
    aliases: string[];
    group: string;
    icon: import("react/jsx-runtime").JSX.Element;
    subtext: string;
};
