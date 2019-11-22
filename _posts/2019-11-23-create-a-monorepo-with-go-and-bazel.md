---
layout: default
title:  "Go + Bazel로 모노레포 만들기"
date:   2019-11-23 04:44:00 +0900
---

깃허브를 돌아다니다 보면, 재밌는 프로젝트를 정말 많이 발견할 수 있습니다. [stellar/go](https://github.com/stellar/go) 같은 것들요.

스텔라 정도 되는 프로젝트니 파일 많을 수 있지 싶었는데, 그렇게 생각해도 뭔가 많습니다. 저장소 이름도 뭔가 심상치 않습니다. `Monorepo`라는 문구도 눈에 띕니다. 왠지 흥미가 생겨서 Readme를 읽기 시작하니, 학교 다닐 때 영어 시간에는 잠만 잤던 제 눈에 `home for all of the public Go code`라는 문구가 들어옵니다. Stellar의 모든 Go 기반 소스코드가 여기 있는 모양입니다. Go 특유의 `GOPATH` 덕분에<small>(현재는 Go Modules로 바뀌는 추세지만)</small> 이렇게 저장소를 구성한 것 같습니다. 마침 얼마 전에 [뉴스레터](https://golangweekly.com/issues/288)에서 봤던 [`Bazel`](https://bazel.build/)이라는 빌드 툴이 떠오릅니다. 왠지 삽질하기 좋아 보이고, 며칠은 여기 날리겠구나 싶은 생각이 막 듭니다.

모노레포는 위에서 본 저장소랑 비슷하게, 모든 프로젝트를 전부 집어넣은 저장소를 의미합니다. 이렇게 하면 별도 프로젝트로 분리하기는 싫고, 그렇다고 복붙은 하면 안될 것 같은 애매한 코드들을 재사용 하기 쉬워집니다. 의존성 관리도 아주 간단해지죠. 물론 단점은 많습니다. 심지어 꽤 치명적인 단점들이라 쉽게 도입할만한 물건은 아니죠. 예를 들어, 적당히 큰 기업에서 이 방법으로 저장소를 관리하면 아마 git status만 쳐도 1 분은 놀아야 할 겁니다. 그래서 MS에서는 [VFS for Git](https://vfsforgit.org/)라는 물건을 오픈소스로 풀었고, 구글에서는 위에도 썼던 Bazel을 공개했습니다. 그 외에도 Monorepo를 위한 많은 오픈소스 프로젝트들이 있지만, 이 글에서는 쓰지 않겠습니다.

----

```
mkdir mono; cd mono
git init
go mod init github.com/ybkimm/mono
```

보시다시피, 늘 해왔던 것과 다르지 않습니다. 이 Monorepo를 전부 하나의 모듈로 만들어야 합니다.

이렇게 하면 각각의 패키지는 `github.com/ybkimm/mono/packages/cmd/hello-world` 비슷한 이름을 가지게 되겠네요. 긴 패키지명이 싫으신 분이라면 모듈 이름을 `monorepo`정도로 정해도 괜찮습니다.

이제 Bazel을 위한 파일을 만들어야 합니다. Bazel은 프로젝트를 `Workspace` 단위로 관리합니다. 이 저장소가 `Workspace`가 되니, 저장소 루트에 `WORKSPACE` 파일을 만들고 아래 내용을 입력해주세요.

```
workspace(name = "your_workspace_name")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
        name = "io_bazel_rules_go",
    urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.19.5/rules_go-v0.19.5.tar.gz",
                "https://github.com/bazelbuild/rules_go/releases/download/v0.19.5/rules_go-v0.19.5.tar.gz",
        ],
        sha256 = "513c12397db1bc9aa46dd62f02dd94b49a9b5d17444d49b5a04c5a89f3053c1c",
)

http_archive(
        name = "bazel_gazelle",
        urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
                "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
        ],
        sha256 = "7fc87f4170011201b1690326e8c16c5d802836e3a0d617d8f75c3af2b23180c4",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()
go_register_toolchains()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()
```

워크스페이스를 정의하고 빌드 스크립트의 의존성을 명시하는 파일입니다. 한 줄씩 보면 이렇습니다.

* `workspace(...)` - 워크스페이스 선언입니다. 여기서의 이름은 일단 큰 영향을 주지 않으니, 편한대로 지어주세요.
* `load(...)` - 의존성을 불러옵니다. 첫 파라메터는 `.bzl` 파일의 경로고, 두 번째 파라메터부턴 `http_archive`를 이 파일에서 쓰겠다는 의미입니다.
* `http_archive(...)` - 원격 아카이브를 다운로드 받아 의존성에 추가합니다. load로 불러와야 사용할 수 있습니다!
* `go_rules_dependencies()`, `go_register_toolchains()`, `gazelle_dependencies()` - `rules_go`, [`gazelle`](https://github.com/bazelbuild/bazel-gazelle)를 사용하기 위해 꼭 호출해줘야 하는 함수입니다. Bazel은 Go언어를 기본으로 지원하지 않기 때문에, 플러그인을 추가해서 지원하는 방식입니다.

다음으로 만들 파일은 `BUILD`입니다. Bazel에서는 `BUILD` 파일을 포함하는 디렉토리를 두고 `Package`라고 부릅니다. 루트 패키지를 만드는 셈이네요.

```
load("@bazel_gazelle//:def.bzl", "gazelle")

# gazelle:prefix github.com/example/project
gazelle(name = "gazelle")
```

얘는 단순합니다. Gazelle를 불러오고 끝이네요. 위에 주석으로 이런 저런 것들을 달아줄 수 있는 모양인데, 일단 여기서는 패키지 이름만 적어줍시다.

> 혹시 다른 지시자들이 궁금하시면 [이 링크](https://github.com/bazelbuild/bazel-gazelle#directives)를 참고하세요.

이제 세팅이 다 끝났습니다. 아래 명령으로 저장소를 갱신해봅시다. 참고로 지금 뿐 아니라 추후 새 패키지를 만들 때도 아래 명령을 실행하면 각 패키지에 대한 BUILD 파일을 알아서 생성해주니 참고하세요!

```
$ bazel run //:gazelle -- update-repos -from_file=go.mod
...
```

이제 다 끝났습니다. 적당히 hello, world! 패키지라도 하나 만들어 봅시다.

자동으로 만들어진 `BUILD` 파일은 이렇게 생겼습니다.

```
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

go_binary(
    name = "hello-world",
    embed = [":go_default_library"],
    importpath = "github.com/ybkimm/mono/packages/cmd/hello-world",
    visibility = ["//visibility:public"],
    out = "bin/hello-world"
)

go_test(
    name = "test",
    srcs = ["main_test.go"],
)

go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importpath = "github.com/ybkimm/mono/packages/cmd/hello-world",
    visibility = ["//visibility:private"],
)

go_test(
    name = "go_default_test",
    srcs = ["main_test.go"],
    embed = [":go_default_library"],
)
```

`go_default_library`라는 이름의 라이브러리를 만들고, 그 라이브러리를 바이너리에 포함시켜 빌드하는 것을 볼 수 있습니다.  그리고 이 라이브러리는 `//visibility:private`로 설정되어 있으니, 다른 패키지에서 접근할 수 없다는 뜻이겠죠. `go_binary`를 보시면 `name`이 `hello-world`로 정의되어 있습니다. 아까 본 `gazelle` 같은 경우에도 `name` 파라메터를 정의하고 있었죠.

그러니 이 패키지를 실행하고자 한다면, `gazelle`처럼 다음 명령을 실행하면 됩니다.

```
$ bazel run //packages/hello-world:hello-world
Hello, World!
```

빌드나 테스트도 비슷하게 실행할 수 있습니다.

```
$ bazel build //packages/hello-world:hello-world
$ bazel test //packages/hello-world:hello-world
```

이런 식으로 작업하면 됩니다. 직접 `rule`을 작성할 수도 있는데, 이 주제에 대해서도 언젠가 다뤄보면 좋겠네요. Static 파일이라거나, Protobuf 같은 것들 말이죠. 혹은 다른 언어를 추가한다거나.

그럼 끝!