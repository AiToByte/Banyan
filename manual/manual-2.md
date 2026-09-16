给我一些相关的，符合我的需求和实际使用的高质量开源软件或者skill等，尽数罗列出来，并对其进行详细描述和介绍


为了解决你所面临的“**模型额度耗尽中断、换模型/换窗口后上下文断片、重复规划与执行消耗 Token**”的实际痛点，业界已经诞生了大量优秀的开源软件、MCP（Model Context Protocol）插件和服务，以及专项架构方案。

根据它们在整个工作流中承担的职责，以下为你精选并深度解析这些**高质量、完全开源、可直接投入实战**的工具与方案：

---

### 一、 跨会话状态持久化与“记忆库”工具（解决断点续传与进度记录）

这类工具专注于解决**“怎么让 Agent 强制写计划、记日志、读进度”**，让任意 Agent 重新打开时都能无缝接力。

#### 1. Roo Code / Cline: Memory Bank（记忆库体系）
* **项目地址**：`github.com/RooVetGit/Roo-Code` / `github.com/cline/cline`
* **项目性质**：开源自主编程 Agent（VS Code 插件及规范）
* **核心机制与详细介绍**：
  * **Memory Bank 原语**：这是目前开源编码 Agent 领域最成熟的“防上下文丢失”机制。它在项目内建立一系列 Markdown 文件（`projectbrief.md`, `productContext.md`, `activeContext.md`, `systemPatterns.md`, `techContext.md`, `progress.md`）。
  * **状态机约束**：Agent 在开始工作前，必须执行“读取 Memory Bank”；在每一步执行关键操作或切换任务时，强制先更新 `activeContext.md`（当前上下文与下一步焦点）和 `progress.md`（总进度清单）。
  * **在 OpenCode / Claude Code 中的用法**：你不需要完全使用它的 VS Code 插件，可以直接提取其开源仓库中的 **`memory-bank-rules` 提示词模板**，放入任何命令行 Agent（如 Claude Code 的 `CLAUDE.md`）中，即可将任何模型驯化为严格遵循 Memory Bank 的 Agent。

#### 2. Sequential Thinking MCP Server
* **项目地址**：`github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking`
* **项目性质**：Anthropic 官方开源维护的 MCP 标准思维链服务
* **核心机制与详细介绍**：
  * **动态动态思维与规划状态机**：这是一个专门给支持 MCP 的 Agent（如 Claude Code）挂载的工具服务。它向 Agent 暴露了结构化思考工具，参数包括 `thought`（当前思考）、`thoughtNumber`（当前步骤）、`totalThoughts`（总步骤预估）、`nextThoughtNeeded`（是否继续）、`isRevision`（是否修正前面的计划）。
  * **防错漏与强制结构化**：避免了纯自然语言让模型自由发挥时“忘记保存中间状态”的问题。所有推理步骤通过 JSON Schema 严格校验并输出，可被外部服务拦截并直接写入磁盘为 `.md` 日志。

#### 3. Task / Todo MCP Servers（轻量级任务流管理）
* **代表开源项目**：
  * `mcp-server-sqlite` / 社区的各类 `task-manager-mcp`、`todo-mcp`
  * `github.com/modelcontextprotocol/servers/tree/main/src/filesystem`（官方文件系统 MCP）
* **核心机制与详细介绍**：
  * **任务原子操作抽象**：为 Agent 提供如 `create_task_list(title, steps)`、`mark_step_complete(step_id, execution_log)`、`get_pending_tasks()` 的原生 Tool Call 接口。
  * **与文件系统深度绑定**：直接将底层存储映射为根目录的 `PLAN.md`。比起让模型随意用 `Bash(echo "...")` 修改文件，Tool Call 的方式保证了 Markdown 的格式绝对不会乱（例如表格对齐、复选框标准 `[ ]` 与 `[x]`）。

---

### 二、 统一模型网关与无缝容灾调度（从根源解决额度耗尽与手动换模型）

频繁换终端、换模型是因为你的 API 客户端直接绑定了某个具体模型。通过开源 API 网关，你可以配置**“自动 Fallback（故障转移）策略”**：当模型 A 遇到 `429 (Rate Limit / Token 耗尽)` 时，网关在**毫秒级无感切换**到模型 B，上层 Agent 甚至不需要重启窗口！

#### 1. LiteLLM（业界最顶级的 LLM 统一路由代理）
* **项目地址**：`github.com/BerriAI/litellm`
* **项目性质**：开源 LLM 代理服务器 / Python 库
* **核心机制与详细介绍**：
  * **OpenAI 兼容代理**：本地启动一条命令 `litellm --config config.yaml`，即在 `localhost:4000` 启动一个统一网关。无论 Claude Code、OpenCode 还是 Aider，都统一指向这个本地端口。
  * **原生模型 Fallback 与负载均衡**：你可以在配置文件中定义极其灵活的容灾组：
    ```yaml
    model_list:
      - model_name: coding-agent
        litellm_params:
          model: anthropic/claude-3-5-sonnet
          api_key: sk-ant-...
      - model_name: coding-agent
        litellm_params:
          model: deepseek/deepseek-chat
          api_key: sk-...
      - model_name: coding-agent
        litellm_params:
          model: gemini/gemini-1.5-pro
          api_key: AIza...
    router_settings:
      fallbacks: [{"coding-agent": ["deepseek/deepseek-chat", "gemini/gemini-1.5-pro"]}]
      cooldown_time: 3600 # 触发限流后冷却1小时，自动恢复主模型
    ```
  * **效果**：你在 Claude Code 里只要调 `coding-agent`，免费 Claude 额度用光（返回 429）后，LiteLLM 立即把当前请求透明转发给 DeepSeek 或 Gemini。任务连贯执行，**彻底告别手动关终端换配置**。

#### 2. New-API / One-API
* **项目地址**：`github.com/Calcium-Ion/new-api` / `github.com/songquanpeng/one-api`
* **项目性质**：开源多渠道大模型资产分发与聚合系统（自带 Web UI）
* **核心机制与详细介绍**：
  * **多 Key 与免费渠道轮询池**：如果你收集了多个服务商的免费额度（如 Google Cloud/Gemini 免费额度、Groq 免费额度、硅基流动/智谱等各大平台的免费 Token），你可以将它们统统添加为一个通用的聚合模型分组。
  * **重试与禁用判定**：一个渠道额度扣减耗尽或报错超限，系统自动停用该渠道并切换至备用渠道，向上暴露一个稳定的 `sk-` 密钥，对各类 Agent 极度友好。

---

### 三、 原生具备“状态持久化与断点续做”的开源 Agent

如果你不局限于现有的轻量 CLI，以下这些成熟的开源 Coding Agent 框架在架构设计上就已经天然具备了持久化与会话恢复能力：

#### 1. OpenHands (原 OpenDevin)
* **项目地址**：`github.com/All-Hands-AI/OpenHands`
* **项目性质**：基于 Docker 沙盒的开源自主软件工程师 Agent
* **核心机制与详细介绍**：
  * **Event Stream（事件流）持久化架构**：OpenHands 不把对话当作简单的聊天文本，而是将规划、执行、命令输出、文件变动全部序列化为 Event Stream 存储在本地数据库中。
  * **原生断点接力（Resume Session）**：任何任务中断、模型崩溃或手动停止，进入 Dashboard 直接点击“Resume”，它会读取完整的历史事件轨迹，重新生成当前待办，无需重新灌入背景资料。

#### 2. Aider (`aider-chat`)
* **项目地址**：`github.com/aider-chat/aider`
* **项目性质**：目前公认最硬核的终端结对编程命令行工具
* **核心机制与详细介绍**：
  * **Architect / Editor 双模型分工模式**：Aider 支持配置两个模型协同（`--architect` 模式）。你可以让一个高智力模型（做规划）制定方案，再由一个低消耗/免费模型根据方案落盘代码。
  * **Git 原生 Checkpoint（Git 级状态恢复）**：Aider 每次完成一个步骤，会自动执行包含详细语义的 `git commit`。如果任务中途因为 Token 耗尽崩掉，只要在同一个仓库重新运行 `aider`，它会自动感知 Git 状态树的变化，输入 `/undo` 可以精确回滚到断点前，输入 `/run` 能继续执行后续测试。

#### 3. SWE-agent
* **项目地址**：`github.com/princeton-nlp/SWE-agent`
* **项目性质**：普林斯顿大学开源的代码修复 Agent 系统
* **核心机制与详细介绍**：
  * **ACI（Agent-Computer Interface）与轨迹日志（Trajectory）**：SWE-agent 执行任何代码修复任务时，会严格把每一步的“观察（Observation）- 思考（Thought）- 行动（Action）”全部存为 `.traj`（轨迹文件）。
  * 这种纯粹的结构化日志天然支持重放（Replay）和任务续期，是学术界和工业界参考任务断点持久化的经典范本。

---

### 四、 快速落地组合方案推荐（从拿来即用到工业级方案）

| 需求阶段 | 推荐使用的开源技术组合 | 实施步骤 |
| :--- | :--- | :--- |
| **方案 A：极速改造（无需代码）** | **Roo-Code Memory Bank 规范** + **你现有的 Claude Code/OpenCode** | 1. 复制 Roo-Code 的 `memory-bank` 提示词逻辑至工作区的 `CLAUDE.md`。<br>2. 强制要求生成 `TASK_PLAN.md` 与 `EXEC_LOG.md`。<br>3. 换模型后一键执行“读取两个 md 文件并继续执行”指令。 |
| **方案 B：网络层无感容灾（最省心）** | **LiteLLM (开源网关)** + **任意 Coding CLI** | 1. 本地 `docker run` 或 `pip install litellm`。<br>2. 配置 Fallback：主用模型（Claude 免费额度） -> 备用模型 1（DeepSeek） -> 备用模型 2（Gemini）。<br>3. CLI 代理指向 LiteLLM，Token 用尽时底层毫秒级静默切换，无需人工介入。 |
| **方案 C：工程化规范约束** | **Sequential Thinking MCP** 或 自建 **Task-Manager MCP** | 1. 在 Agent 的 MCP 配置中挂载思维链与任务管理插件。<br>2. 强迫模型每一步通过结构化 JSON Tool 存盘，保证 Markdown 日志绝对不格式崩坏。 |