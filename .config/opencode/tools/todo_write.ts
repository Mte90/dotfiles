import { type Plugin, tool } from "@opencode-ai/plugin"

export const TodoManagerPlugin: Plugin = async ({ client, $ }) => {
    return {
        tool: {
            todo_manager: {
                description:
                "Creates and manages a structured task list for the current coding session. " +
                "Pass the full updated todo list to replace the current one.",
                args: tool.schema
                .object({
                    todos: tool.schema
                    .array(
                        tool.schema.object({
                            content: tool.schema
                            .string()
                            .describe("Brief description of the task"),
                                           status: tool.schema
                                           .string()
                                           .describe(
                                               "Current status: pending | in_progress | completed | cancelled"
                                           ),
                                           priority: tool.schema
                                           .string()
                                           .describe("Priority level: high | medium | low"),
                        })
                    )
                    .describe("The full updated todo list"),
                }),
                execute: async (args: any, context: any) => {
                    try {
                        const updated = args.todos.length
                        const summary = args.todos
                        .map(
                            (t: any) =>
                            `[${t.priority.toUpperCase()}] ${t.status} — ${t.content}`
                        )
                        .join("\n")

                        return (
                            `✅ Todo list updated (${updated} item${updated !== 1 ? "s" : ""}):\n\n` +
                            summary
                        )
                    } catch (err: any) {
                        return `❌ Failed to update todos: ${err?.message ?? String(err)}`
                    }
                },
            },
        },
    }
}
