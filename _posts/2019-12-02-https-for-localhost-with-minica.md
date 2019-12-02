---
layout: default
title:  "Minica로 Localhost를 위한 인증서 만들기"
date:   2019-12-02 22:15:30 +0900
---

로컬에서 개발하다 보면 `localhost`에 대한 인증서를 발급받고 싶어지는 경우가 있습니다.

크롬이 [HTTP를 안전하지 않다고](https://www.blog.google/products/chrome/milestone-chrome-security-marking-http-not-secure/) 표기하기 시작한 뒤로 더 그렇습니다.

현재는 [Let's Encrypt](https://letsencrypt.org/)같은 CA가 생기고, 모든 웹사이트에 인증서를 다는 것이 일반적인 상황이 되었죠.

HTTP와 HTTPS에서 브라우저는 조금 다르게 동작하기 때문에 실제 테스트 환경에서도 SSL 인증서를 발급받아 쓰는 편이 좋습니다. 당연한 말이지만, 실제 CA에서는 발급해주지 않습니다.

그래서 HTTPS를 달고 쓰려면 사설 인증서를 발급해야 하지만...

```
openssl req -x509 -out localhost.crt -keyout localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=localhost' -extensions EXT -config <( \
    printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```
<sup>▲ [https://letsencrypt.org/docs/certificates-for-localhost/](https://letsencrypt.org/docs/certificates-for-localhost/)</sup>

명령어보다는 암호문에 더 가까워 보이네요. 다음 달에 인증서 하나 더 만들 일 생기면 아마 구글부터 켜게 되겠죠. 굳이 이걸 쓰고싶지는 않습니다.
물론 스크립트 하나 짜서 할 수는 있겠지만 어쩌다 한 번 발급하는 인증서를 위해 그런 수고를 들이기는 싫고.

# Minica

[Minica](https://github.com/jsha/minica)는 실제 CA에서 발급받은 것과 유사한 인증서를 아주 간편하게 발급해주는 프로그램입니다.
Go 언어로 작성되었고, 그래서 외부 의존성이 없습니다!

설치는 다음 명령어로 할 수 있습니다.

```
go get -u github.com/jsha/minica
```

만약 Go 언어를 사용하지 않으셔서 go 명령어를 쓸 수 없는 경우라면 제가 빌드한 바이너리를 아래 링크에서 다운로드 하실 수 있습니다.

* Linux: [amd64](/assets/files/2019-12-02-https-for-localhost-with-minica/linux_amd64/minica), [386](/assets/files/2019-12-02-https-for-localhost-with-minica/linux_386/minica), [arm](/assets/files/2019-12-02-https-for-localhost-with-minica/linux_arm/minica), [arm64](/assets/files/2019-12-02-https-for-localhost-with-minica/linux_arm64/minica)
* Windows: [amd64](/assets/files/2019-12-02-https-for-localhost-with-minica/windows_amd64/minica.exe), [386](/assets/files/2019-12-02-https-for-localhost-with-minica/windows_386/minica.exe)
* macOS: [amd64](/assets/files/2019-12-02-https-for-localhost-with-minica/darwin_amd64/minica)

![](/assets/images/2019-12-02-https-for-localhost-with-minica/minica-help.png)

다음과 같이 사용하면 됩니다.

```
$ mkdir certs; cd certs
$ minica -domains www.localhost,localhost -ip-addresses 127.0.0.1
```

꼭 도메인에만 써야 하는건 아닙니다. [1.1.1.1](https://1.1.1.1/)처럼 IP에 인증서를 발급할 수도 있죠.

![](/assets/images/2019-12-02-https-for-localhost-with-minica/cert-for-ip-demo.png)

한번 발급한 인증서는 2년하고도 30일간 유효합니다. CA 루트 인증서는 100년간 유효합니다.

