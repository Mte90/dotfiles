import { tool } from "@opencode-ai/plugin"

export default tool({
    description: "Alias for todowrite. Use this tool to create and manage a structured task list for your current coding session.",
    args: {
        todos: tool.schema.array(
            tool.schema.object({
                content: tool.schema.string().describe("Brief description of the task"),
                status: tool.schema.string().describe("Current status: pending, in_progress, completed, cancelled"),
                priority: tool.schema.string().describe("Priority level: high, medium, low"),
            })
        ).describe("The updated todo list"),
    },
    async execute(args, ctx) {
        // chiama l'API interna del server opencode
        const res = await fetch(`http://localhost:${ctx.port ?? 4096}/session/${ctx.sessionID}/todo`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ todos: args.todos }),
        })
        return res.ok ? `Updated ${args.todos.length} todos` : `Error: ${res.statusText}`
    },
})
