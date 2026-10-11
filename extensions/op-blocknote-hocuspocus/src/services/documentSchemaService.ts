//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Ajv, type ErrorObject } from "ajv";
import { editorSchema } from "../editor";

type JsonSchema = Record<string, unknown>;

interface PropSpec {
  default?: unknown;
  type?: "string" | "number" | "boolean";
  values?: readonly unknown[];
}

interface ContentSpec {
  type: string;
  propSchema?: Record<string, PropSpec> | "boolean" | "string";
  content?: "inline" | "plain" | "table" | "none" | "styled";
}

const TABLE_CELL_PROPS: Record<string, PropSpec> = {
  backgroundColor: { default: "default" },
  textColor: { default: "default" },
  textAlignment: { default: "left", values: ["left", "center", "right", "justify"] },
  colspan: { default: 1 },
  rowspan: { default: 1 },
};

function propSchema(spec: PropSpec): JsonSchema {
  if (spec.values) {
    return { enum: [...spec.values] };
  }

  const type = spec.type ?? typeof spec.default;
  return ["string", "number", "boolean"].includes(type) ? { type } : {};
}

function propsSchema(props: Record<string, PropSpec>): JsonSchema {
  return {
    type: "object",
    additionalProperties: false,
    properties: Object.fromEntries(
      Object.entries(props).map(([name, spec]) => [name, propSchema(spec)]),
    ),
  };
}

function discriminated(specs: { type: string, schema: JsonSchema }[]): JsonSchema {
  return {
    type: "object",
    required: ["type"],
    properties: { type: { enum: specs.map(({ type }) => type) } },
    allOf: specs.map(({ type, schema }) => ({
      if: { properties: { type: { const: type } } },
      then: schema,
    })),
  };
}

function stylesSchema(): JsonSchema {
  const styles = Object.values(editorSchema.styleSchema) as ContentSpec[];

  return {
    type: "object",
    additionalProperties: false,
    properties: Object.fromEntries(
      styles.map(({ type, propSchema }) => [type, { type: propSchema }]),
    ),
  };
}

function customInlineSchema(spec: ContentSpec): JsonSchema {
  const properties: JsonSchema = {
    type: { const: spec.type },
    props: propsSchema(spec.propSchema as Record<string, PropSpec>),
  };
  if (spec.content === "styled") {
    properties.content = { $ref: "#/definitions/styledTextList" };
  }

  return { additionalProperties: false, properties };
}

function inlineContentSchema(): JsonSchema {
  const specs = Object.values(editorSchema.inlineContentSchema) as (ContentSpec | string)[];

  return discriminated(specs.map((spec) => {
    if (spec === "text") {
      return { type: "text", schema: { $ref: "#/definitions/styledText" } };
    }
    if (spec === "link") {
      return { type: "link", schema: { $ref: "#/definitions/link" } };
    }

    const custom = spec as ContentSpec;
    return { type: custom.type, schema: customInlineSchema(custom) };
  }));
}

function tableContentSchema(): JsonSchema {
  const cell = {
    anyOf: [
      { $ref: "#/definitions/inlineContentList" },
      {
        type: "object",
        additionalProperties: false,
        required: ["type"],
        properties: {
          type: { const: "tableCell" },
          props: propsSchema(TABLE_CELL_PROPS),
          content: { $ref: "#/definitions/inlineContentList" },
        },
      },
    ],
  };

  return {
    type: "object",
    additionalProperties: false,
    required: ["type", "rows"],
    properties: {
      type: { const: "tableContent" },
      columnWidths: { type: "array", items: { type: ["number", "null"] } },
      headerRows: { type: "integer", minimum: 0 },
      headerCols: { type: "integer", minimum: 0 },
      rows: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["cells"],
          properties: { cells: { type: "array", items: cell } },
        },
      },
    },
  };
}

function blockContentSchema(content: ContentSpec["content"]): JsonSchema | false {
  switch (content) {
    case "inline":
      return { $ref: "#/definitions/inlineContentList" };
    case "plain":
      return { $ref: "#/definitions/styledTextList" };
    case "table":
      return { $ref: "#/definitions/tableContent" };
    default:
      return false;
  }
}

function blockSchema(): JsonSchema {
  const specs = Object.values(editorSchema.blockSchema) as unknown as ContentSpec[];

  const block = discriminated(specs.map((spec) => ({
    type: spec.type,
    schema: {
      properties: {
        props: propsSchema(spec.propSchema as Record<string, PropSpec>),
        content: blockContentSchema(spec.content),
      },
    },
  })));

  return {
    ...block,
    additionalProperties: false,
    properties: {
      ...(block.properties as JsonSchema),
      id: { type: "string", minLength: 1 },
      props: { type: "object" },
      content: {},
      children: { type: "array", items: { $ref: "#/definitions/block" } },
    },
  };
}

export function buildDocumentJsonSchema(): JsonSchema {
  return {
    $schema: "http://json-schema.org/draft-07/schema#",
    $id: "https://www.openproject.org/schemas/documents/blocknote.json",
    title: "OpenProject document (BlockNote blocks)",
    description:
      "The content of an OpenProject document as an array of BlockNote blocks. " +
      "Blocks keep their `id` across edits. Omit `id` for new blocks. " +
      "Omitted `props` fall back to their defaults. " +
      "Inline content may be given as a plain string as a shorthand for unstyled text.",
    type: "array",
    items: { $ref: "#/definitions/block" },
    definitions: {
      block: blockSchema(),
      styledText: {
        type: "object",
        additionalProperties: false,
        required: ["type", "text"],
        properties: {
          type: { const: "text" },
          text: { type: "string" },
          styles: stylesSchema(),
        },
      },
      styledTextList: {
        anyOf: [
          { type: "string" },
          { type: "array", items: { $ref: "#/definitions/styledText" } },
        ],
      },
      link: {
        type: "object",
        additionalProperties: false,
        required: ["type", "href", "content"],
        properties: {
          type: { const: "link" },
          href: { type: "string" },
          content: { $ref: "#/definitions/styledTextList" },
        },
      },
      inlineContent: inlineContentSchema(),
      inlineContentList: {
        anyOf: [
          { type: "string" },
          { type: "array", items: { $ref: "#/definitions/inlineContent" } },
        ],
      },
      tableContent: tableContentSchema(),
    },
  };
}

export const documentJsonSchema = buildDocumentJsonSchema();

const validator = new Ajv({ allErrors: true, strict: false }).compile(documentJsonSchema);

export type ValidationResult = { valid: true } | { valid: false, errors: string[] };

function formatError({ instancePath, message, params }: ErrorObject): string {
  const detail = "allowedValues" in params ? ` (${(params.allowedValues as unknown[]).join(", ")})` : "";
  const extra = "additionalProperty" in params ? ` '${params.additionalProperty}'` : "";
  return `${instancePath || "/"} ${message}${extra}${detail}`;
}

export function validateBlocks(blocks: unknown): ValidationResult {
  if (validator(blocks)) {
    return { valid: true };
  }

  const errors = [...new Set((validator.errors ?? [])
    .filter(({ keyword }) => keyword !== "if")
    .map(formatError))];

  return { valid: false, errors };
}
