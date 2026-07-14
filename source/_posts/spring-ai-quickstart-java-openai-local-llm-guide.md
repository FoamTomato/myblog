---
title: "Spring AI Quickstart: A Complete Guide for Java Developers to Integrate OpenAI and Local LLMs"
date: 2026-07-14 00:00:00
categories:
  - 技术随笔
description: 本文面向有Spring Boot基础的Java后端开发者，系统讲解如何借助Spring AI框架快速集成OpenAI云端API与Ollama本地大模型，涵盖项目初始化、配置、核心接口编写、结构化输出、RAG及Function Calling等完整链路，是Java工程师转型AI应用开发的实用入门指南。
---

![Spring AI 快速入门：Java 开发者集成 OpenAI 与本地大模型完整指南](https://seo-resouce.pandaclaws.ai/ai-generated-pro/20260702/spring-ai-quickstart-java-openai-local-llm-integration-guide.png?v=1782972092)  

**ALT:** Spring AI 快速入门教程，Java 开发者集成 OpenAI 与本地 LLM 大模型完整实战指南

## Java 开发者必读：用 Spring AI 打通大模型集成的任督二脉

> **Key Conclusion**：Spring AI 是 Spring 生态为 AI 大模型应用开发量身打造的框架，让 Java 开发者无需深陷 Python 生态，就能以熟悉的编程范式快速接入 OpenAI、Ollama 等主流大模型服务。无论是云端 API 还是本地部署的 LLM，Spring AI 都提供了统一的抽象层，大幅降低集成成本，是 Java 后端转型 AI 应用开发的最佳入口。

对于大多数 Java 后端开发者来说，AI 大模型的集成曾经是一道隐形的门槛——不是技术本身有多难，而是生态的割裂感太强。Python 社区的 LangChain、LlamaIndex 固然强大，但切换语言栈的成本让不少 Java 工程师望而却步。

好消息是，Spring 官方团队在 2023 年末正式推出了 **Spring AI** 项目，将大模型集成能力直接带进了 Spring 生态。它借鉴了 LangChain 的设计思想，同时保持了 Spring 一贯的"约定优于配置"风格，让 Java 开发者可以用最熟悉的方式构建 AI 驱动的应用程序。

本文将带你从零开始，完整走通 Spring AI 的快速入门流程，涵盖接入 OpenAI 云端服务和在本地运行开源 LLM（通过 Ollama）两条路线，适合有 Spring Boot 基础、想快速上手 AI 应用开发的工程师。

---

## 适用场景说明

✅ **Applicable Scenarios**：

- 有 Spring Boot 开发经验，希望快速接入 OpenAI GPT 系列模型进行 AI 功能开发
- 需要在本地或私有化环境部署开源 LLM（如 Llama 3、Qwen、Mistral），保护数据隐私
- 正在构建聊天机器人、RAG 知识库问答、智能文档处理等 AI 应用的 Java 后端工程师
- 希望从 Java 技术栈出发，向 AI 大模型应用开发方向转型的中级开发者

❌ **Not Applicable/Cautions**：

- 完全没有 Java/Spring Boot 基础的初学者（建议先补充 Spring Boot 入门知识）
- 追求极致推理性能、需要深度定制模型推理引擎的场景（Spring AI 侧重应用层集成，非底层推理优化）
- 期望直接使用 Python 生态工具链（LangChain、FastAPI）的场景，本文不涉及跨语言方案

---

## 为什么 Java 开发者现在就该学 Spring AI

长期以来，AI 应用开发几乎是 Python 的专属领地。但随着大模型 API 化趋势愈发明显，"AI 能力作为服务"的模式让任何编程语言都能平等接入。与此同时，企业级 AI 应用对工程化、可维护性、与现有系统集成的要求，恰恰是 Java 生态的强项。

**Spring AI 的出现，本质上是一次生态补位**。它在 Spring 框架成熟的依赖注入、配置管理、测试支持基础上，提供了对话模型（Chat Model）、嵌入模型（Embedding Model）、向量数据库（Vector Store）、提示词模板（Prompt Template）、RAG 流水线等一系列 AI 应用开发所需的核心抽象。

从市场趋势来看，越来越多的企业开始将 AI 能力嵌入到现有的 Java 微服务架构中，而不是单独维护一套 Python 服务。这意味着掌握 Spring AI，能让你在团队中直接成为"AI 集成专家"，无需切换语言栈，就能交付具备智能对话、文档理解、语义搜索等能力的后端服务。

目前 Spring AI 已支持的模型提供商涵盖 OpenAI、Azure OpenAI、Google Vertex AI、Anthropic Claude、Mistral AI，以及通过 Ollama 接入的本地开源模型。这种"多后端统一接口"的设计，让你写一套代码就能在不同模型之间灵活切换，极大降低了厂商锁定风险。

---

## Spring AI 集成实战：从零到可运行

### 三步快速启动

**Step 1：初始化 Spring Boot 项目并引入 Spring AI 依赖**

前往 [Spring Initializr](https://start.spring.io) 创建一个 Spring Boot 3.x 项目，选择 Java 17+。在依赖项中搜索并添加 **Spring AI OpenAI** 或 **Spring AI Ollama**（根据你的集成目标选择）。目前 Spring AI 的 Release 版本托管在 Spring 官方 Milestone 仓库，需要在 `pom.xml` 中额外配置仓库地址。整个初始化过程约需 5 分钟。

```java
<!-- 在 pom.xml 中添加 Spring AI BOM 统一管理版本 -->
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.ai</groupId>
      <artifactId>spring-ai-bom</artifactId>
      <version>1.0.0</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>

<!-- 接入 OpenAI -->
<dependency>
  <groupId>org.springframework.ai</groupId>
  <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
</dependency>
```

**Step 2：配置模型参数与 API Key**

在 `application.yml` 中配置对应的连接参数。接入 OpenAI 时，你需要填入有效的 API Key；接入本地 Ollama 时，则指向本地服务地址（默认为 `http://localhost:11434`）。Spring AI 的 AutoConfiguration 机制会自动完成 Bean 注册，无需手动编写配置类，约 3 分钟即可完成。

```yaml
# 接入 OpenAI 的配置示例
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o-mini
          temperature: 0.7

# 接入本地 Ollama 的配置示例（二选一）
# spring:
#   ai:
#     ollama:
#       base-url: http://localhost:11434
#       chat:
#         options:
#           model: llama3
```

**Step 3：编写第一个 AI 对话接口**

通过 Spring 依赖注入获取 `ChatClient` 实例，即可用极简代码实现对话调用。`ChatClient` 是 Spring AI 的核心门面接口，屏蔽了底层不同模型 SDK 的差异。以下代码在 OpenAI 和 Ollama 之间切换，仅需修改配置文件，业务代码完全不变，约 10 分钟即可验证运行效果。

```java
@RestController
@RequestMapping("/ai")
public class ChatController {

    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    @GetMapping("/chat")
    public String chat(@RequestParam String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
```

### OpenAI 云端 vs Ollama 本地：集成方案横向对比

在实际项目选型中，开发者往往需要在云端 API 和本地部署之间做取舍。以下对比涵盖了选型时最关键的几个维度，帮助你根据项目需求快速决策。

| 对比维度 | OpenAI 云端 API | Ollama 本地部署 | Azure OpenAI |
| --- | --- | --- | --- |
| 数据隐私 | 数据上传至云端，需遵守服务条款 | 完全本地运行，数据不出内网 | 企业级数据隔离，合规性较强 |
| 模型质量 | GPT-4o 等顶级闭源模型，综合能力强 | 取决于选用的开源模型，持续进步 | 与 OpenAI 同款模型，质量一致 |
| 使用成本 | 按 Token 计费，规模化后成本可观 | 一次性硬件投入，运行成本极低 | 按量计费，价格与 OpenAI 相近 |
| 部署复杂度 | 极简，注册获取 Key 即可使用 | 需本地安装 Ollama 并拉取模型 | 需在 Azure 门户部署，配置稍多 |
| Spring AI 支持 | 官方一级支持，功能最完整 | 官方支持，功能持续补齐 | 官方一级支持，与 OpenAI 接口兼容 |
| 适用场景 | 快速原型、追求模型能力上限 | 私有化部署、离线环境、敏感数据 | 企业级生产环境、需要 SLA 保障 |

### 深入理解 Spring AI 核心概念

#### ChatClient 与 Prompt 的设计哲学

**ChatClient** 是 Spring AI 1.0 引入的高层 API，采用 Builder 模式和流式调用风格，让对话逻辑的表达更加直观。相比早期版本直接使用 `ChatModel`，`ChatClient` 内置了对系统提示词、对话历史、工具调用等特性的统一支持。

在实际开发中，你可以在 `ChatClient.Builder` 层面设置全局的系统提示词，在每次调用时注入动态的用户消息，还可以通过 `.advisors()` 方法挂载拦截器（例如 `MessageChatMemoryAdvisor` 用于自动管理对话上下文），让 AI 应用具备真正的"多轮对话"能力。

```java
// 带系统提示词和对话记忆的 ChatClient 构建示例
@Bean
public ChatClient chatClient(ChatClient.Builder builder) {
    return builder
        .defaultSystem("你是一位专业的 Java 技术顾问，回答简洁准确。")
        .defaultAdvisors(new MessageChatMemoryAdvisor(new InMemoryChatMemory()))
        .build();
}
```

#### 本地 LLM 的完整接入流程（Ollama 篇）

对于希望在本地运行开源大模型的开发者，**Ollama** 是目前最友好的本地推理工具。它支持一键拉取并运行 Llama 3、Qwen2、Mistral、Phi-3 等主流开源模型，并提供兼容 OpenAI 格式的 REST API。

接入流程如下：

1. 访问 [Ollama 官网](https://ollama.com) 下载安装包，支持 macOS、Linux、Windows
2. 在终端执行 `ollama pull llama3`（或其他你需要的模型）拉取模型文件
3. Ollama 服务默认在 `http://localhost:11434` 启动，Spring AI 的 Ollama Starter 会自动对接
4. 在 `application.yml` 中将模型名称改为你已拉取的模型即可运行

需要特别注意的是，本地运行大模型对硬件有一定要求。7B 参数的模型在 16GB 内存的机器上运行流畅，更大的模型则需要更多内存或 GPU 加速。对于开发调试来说，7B 或 8B 级别的模型已经足够验证业务逻辑。

#### Structured Output：让模型返回结构化 Java 对象

在实际业务场景中，我们往往不只是需要模型返回一段文字，而是需要它输出符合特定格式的结构化数据。Spring AI 提供了 **Structured Output** 功能，可以将模型的文本响应自动映射为 Java Record 或 POJO：

```java
record MovieRecommendation(String title, String genre, String reason) {}

MovieRecommendation result = chatClient.prompt()
    .user("推荐一部适合程序员看的科幻电影，返回电影名、类型和推荐理由")
    .call()
    .entity(MovieRecommendation.class);

System.out.println(result.title()); // 直接获取结构化字段
```

Spring AI 会在底层自动生成格式指令并注入到 Prompt 中，处理模型返回的 JSON 字符串并完成反序列化，整个过程对开发者几乎透明。

![Spring AI 核心架构图：ChatClient、ChatModel、VectorStore 组件关系示意](https://seo-resouce.pandaclaws.ai/ai-generated-pro/20260702/spring-ai-architecture-chatclient-openai-ollama-vectorstore-rag-pipeline.png?v=1782972092)  

**ALT:** Spring AI 架构图，展示 ChatClient 与 OpenAI、Ollama 等多模型后端的集成关系，以及 VectorStore RAG 流水线组件

---

## 进阶：Spring AI 的高级特性与常见误区

### Function Calling：让模型调用你的业务方法

Spring AI 支持 **Function Calling**（工具调用），允许你将自定义的 Java 方法注册为模型可调用的"工具"。当用户的问题需要查询实时数据或执行业务逻辑时，模型会自动识别并触发相应的方法调用。

```java
@Bean
@Description("查询指定城市的实时天气")
public Function<WeatherRequest, WeatherResponse> currentWeather() {
    return request -> weatherService.getWeather(request.city());
}
```

将这个 Bean 注册后，在 `ChatClient` 调用时通过 `.functions("currentWeather")` 传入即可。这是构建 AI Agent 的核心能力之一，值得深入探索。

### RAG 流水线：为模型注入私有知识

**检索增强生成（RAG）** 是当前最主流的企业级 AI 应用模式。Spring AI 提供了完整的 RAG 支持，包括文档读取（`DocumentReader`）、文本分块（`TextSplitter`）、向量化存储（`VectorStore`）和相似度检索，支持 PGVector、Redis、Chroma、Pinecone 等多种向量数据库。

### 常见误区澄清

**误区一：Spring AI 只支持 OpenAI**。事实上，Spring AI 设计之初就以"模型无关性"为核心目标，支持十余种模型提供商，Ollama 本地模型同样是一类支持。

**误区二：必须使用最新的 GPT-4 才能做出好产品**。对于大多数业务场景，GPT-4o-mini 或本地的 Llama 3 8B 模型已经完全够用，合理的 Prompt 工程和 RAG 架构比模型本身更重要。

**误区三：Spring AI 还不成熟，不适合生产环境**。Spring AI 1.0 GA 版本已经发布，Spring 官方给予了明确的长期支持承诺，企业可以放心引入。

---

## 常见问题 FAQ

### Q1：如何在 Spring AI 中实现流式（Stream）输出效果？

Spring AI 原生支持流式响应，通过 `chatClient.prompt().user(msg).stream().content()` 即可获取 `Flux` 类型的响应流。结合 Spring WebFlux 和 Server-Sent Events（SSE），可以轻松实现类似 ChatGPT 逐字输出的打字机效果。在 Controller 层将返回类型声明为 `Flux` 并设置 `produces = MediaType.TEXT_EVENT_STREAM_VALUE` 即可，无需额外依赖，整个改造过程通常在半小时以内完成。

### Q2：Spring AI 是否支持多模态（图像、音频）输入？

是的，Spring AI 已经支持多模态输入。对于支持视觉能力的模型（如 GPT-4o、LLaVA），可以通过 `UserMessage` 携带图像内容，Spring AI 会自动将图片编码为 Base64 或 URL 形式传递给模型。需要注意的是，多模态能力取决于后端模型本身是否支持，并非所有模型都具备视觉理解能力，本地 Ollama 模型需选择带有视觉能力的版本（如 llava 系列）。

### Q3：接入 OpenAI 的费用大概是多少，适合个人开发者学习使用吗？

OpenAI 按 Token 计费，GPT-4o-mini 是目前性价比最高的入门选择，价格极为亲民，日常学习和原型开发产生的费用通常可以忽略不计。新注册用户还可能获得一定额度的免费试用额度。如果完全不想产生云端费用，使用 Ollama 在本地运行开源模型是零成本的替代方案，非常适合学生和个人开发者在本地环境中学习 Spring AI 的完整用法。

---

## 总结

通过本文的系统梳理，我们完整走通了 Java 开发者借助 Spring AI 快速上手大模型集成的全流程：

**核心收获三点**：

1. **Spring AI 是 Java 后端接入大模型的最低摩擦路径**——统一抽象层让 OpenAI 和本地 LLM 的切换仅需修改配置，业务代码零改动
2. **云端 + 本地双路线各有适用场景**——OpenAI 追求能力上限，Ollama 保障数据隐私，两者在 Spring AI 框架下使用体验高度一致
3. **从基础对话到 RAG、Function Calling，Spring AI 具备构建生产级 AI 应用的完整能力**——不只是玩具级 Demo，而是可以真正落地的工程方案

**下一步行动建议**：先跑通本文的基础 Demo，再尝试接入 Ollama 体验本地模型，最后挑战实现一个带有 RAG 知识库的智能问答服务——这条路径是当前 Java 开发者向 AI 应用方向拓展的最清晰学习曲线。

### Call to Action

如果本文对你有所帮助，欢迎访问**喵喵鱼塘（xiaohang.site）**，这里汇聚了 Java 后端工程实践与 AI 大模型应用开发的系统化教程与实战笔记，持续助力你的技术成长。点击 [https://xiaohang.site/](https://xiaohang.site/) 探索更多干货内容，和博主 Foam🍅 一起在技术的海洋里畅游吧！

---

## References

1. Spring 官方文档. "Spring AI Reference Documentation".    [https://docs.spring.io/spring-ai/reference/](https://docs.spring.io/spring-ai/reference/)
2. OpenAI. "OpenAI API Documentation".    [https://platform.openai.com/docs](https://platform.openai.com/docs)
3. Ollama. "Ollama Official Documentation and Model Library".    [https://ollama.com/library](https://ollama.com/library)
4. Spring Initializr. "Bootstrap your application with Spring Boot".    [https://start.spring.io](https://start.spring.io)
5. GitHub - spring-projects/spring-ai. "Spring AI Source Repository and Examples".    [https://github.com/spring-projects/spring-ai](https://github.com/spring-projects/spring-ai)

*Note: 以上文档版本持续迭代，建议以各官方网站最新发布版本为准，结合实际项目需求进行配置参考。*

---

**关于作者**

本文来自 **喵喵鱼塘（xiaohang.site）**，由开发者 Foam🍅 运营的个人技术博客，专注 Java 后端工程实践与 AI 大模型应用开发，提供覆盖 9 大技术分类的高质量实战笔记与系统化教程。

> ⚠️ **版权声明**：本文为喵喵鱼塘原创内容，转载请注明出处并附原文链接。文中观点仅代表作者个人技术实践与理解，不构成任何商业建议，请读者结合实际情况自行判断与应用。
