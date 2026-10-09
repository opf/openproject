export const INLINE_WP_TYPE = 'openProjectWorkPackageInline' as const;
export const BLOCK_WP_TYPE = 'openProjectWorkPackageBlock' as const;

export const INLINE_WP_ATTRIBUTE_TYPE = 'openProjectWorkPackageAttributeInline';
export const BLOCK_WP_ATTRIBUTE_TYPE = 'openProjectWorkPackageAttributeBlock';

export const WORK_PACKAGE_NODE_TYPES:string[] = [INLINE_WP_TYPE, BLOCK_WP_TYPE, INLINE_WP_ATTRIBUTE_TYPE, BLOCK_WP_ATTRIBUTE_TYPE];

export const USER_MENTION_TYPE = 'openProjectUserMention' as const;
