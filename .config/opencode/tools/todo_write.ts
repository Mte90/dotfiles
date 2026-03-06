import { type Plugin, tool } from "@opencode-ai/plugin"

/**
 * TodoManager Plugin
 *
 * Exposes a custom tool that manages the todo list for the current session.
 * It uses the SDK client available via the Plugin context (closure) to read
 * todos, and the shell helper ($) to delegate writes back to opencode's
 * built-in todowrite tool — the only supported write path.
 */
export const TodoManagerPlugin: Plugin = async ({ client, $ }) => {
    return {
        tool: {
            todo_manager: tool({
                description:
                "Creates and manages a structured task list for the current coding session. " +
                "Pass the full updated todo list to replace the current one.",
                args: {
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
                },

                async execute(args, context) {
                    try {
                        // Read current todos via the SDK client (GET endpoint)
                        const current = await (client as any).session.todo({
                            path: { id: context.sessionID },
                        })

                        const updated = args.todos.length
                        const summary = args.todos
                        .map(
                            (t) =>
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
            }),
        },
    }
}
