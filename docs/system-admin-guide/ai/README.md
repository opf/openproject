---
sidebar_navigation:
  title: Artificial Intelligence
  priority: 925
description: Configure artificial intelligence integrations and text assistance in OpenProject.
keywords: AI, artificial intelligence, LLM, MCP Server, text assistant
---

# AI in OpenProject

OpenProject uses artificial intelligence to make everyday project work easier, while keeping people in control. AI features in OpenProject suggest, but never decide: you review every result and choose whether to use it. Organizations also decide which AI infrastructure they connect, so they can choose a setup that meets their requirements for data protection and digital sovereignty.

OpenProject currently offers two ways of working with AI:

- The **[text assistant](text-assistant/)** helps users write, improve, and structure text directly in OpenProject's editors, for example to proofread a comment or turn rough notes into a structured work package description. The text assistant is an Enterprise add-on and runs on an LLM server that your organization connects.
- The **[MCP Server](mcp-server/)** allows external AI assistants and agents to access OpenProject, for example to search or create work packages. The MCP Server is available in all editions.

> [!CAUTION]
> Always review AI-generated results before using them. AI can introduce assumptions, leave out relevant information, or change the meaning of the original text. It supports your work, but it does not replace human judgment.

Learn more about our approach to AI on the [AI in OpenProject](https://www.openproject.org/ai/) website.

## AI administration

Under _Administration_ > _Artificial Intelligence (AI)_, administrators configure how OpenProject works with artificial intelligence. The section contains three areas:

| Topic                                       | Content                                                      |
| ------------------------------------------- | ------------------------------------------------------------ |
| [LLM settings](llm-settings/)               | Connect OpenProject to an LLM server, manage the available models, and choose which model each AI feature uses. |
| [Text assistant](text-assistant/)           | Manage the text actions that users can apply in the editor, such as proofreading, rewriting, and structuring. |
| [Model Context Protocol (MCP)](mcp-server/) | Allow external AI assistants to access OpenProject through the MCP Server. |

AI features that run inside OpenProject, such as the text assistant, need a connection to an LLM server. The MCP Server does not need one, because the AI assistant runs outside OpenProject.
