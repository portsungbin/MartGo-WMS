# MartGO

## 📌 프로젝트 개요
- WMS(창고 관리 시스템)의 프로세스 학습 및 이해
- Java와 MySQL 연동 경험 (JDBC 사용)
- MVC 패턴을 활용한 구조적 프로그래밍 경험 습득
- 협업 프로세스 및 Git 활용 경험 축적

## 🛠 기술 스택
- Java (JDK 17)
- MySQL (8.0)
- JDBC

## 🚀 설치 및 실행 방법

### 1️⃣ 필수 요구사항
- Java 17 이상 설치
- MySQL 데이터베이스 설치
- MySQL connector 8.0.17 라이브러리 추가

### 2️⃣ 실행 방법
```sh
# 프로젝트 클론
git clone https://github.com/username/project-name.git

# 프로젝트 빌드 및 실행
cd MartGO
java -jar target/MartGO.jar
```

## 📝 기능
- 회원가입 / 로그인 기능
- WMS 시스템을 위한 임대, 입고, 출고 기능 구현
- MySQL을 통한 데이터 저장
- 예외 처리 및 오류 로그 기록

## 📌역할분담
- 강창선(조장) : 재고, 재고변경, 산출물 관리
- 방민영(팀원) : 임대 관리, 용적률 관리, 창고 및 섹터 생성
- 서민성(팀원) : 입고, 출고 프로세스, 제품 등록 시스템
- 임성빈(팀원) : 로그인, 회원가입

## 📂 프로젝트 구조
```shell
📦 MartGo
 ┣ 📂 src
 ┃ ┣ 📂 common
 ┃ ┃ ┣ 📂 config
 ┃ ┃ ┣ 📂 constans
 ┃ ┃ ┣ 📂 exception
 ┃ ┃ ┣ 📂 utils
 ┃ ┣ 📂 controller
 ┃ ┣ 📂 model
 ┃ ┃ ┣ 📂 dao
 ┃ ┃ ┣ 📂 dto
 ┃ ┃ ┣ 📂 service
 ┃ ┣ 📂 view
 ┗ 📜 README.md
```
## 📜 라이선스
이 프로젝트는 신세계 I&C 6차수 3팀 전먹사에 의해 완성되었습니다.

```java
 public void delete() {
        System.out.println("삭제할 아이디를 선택해주세요. ");
        int id = scan.nextInt();
        scan.nextLine();

        svs.delete(id);

        mainMenu();

    }
```

|제목|특징|요소|
|-|-|-|
|1번|2번|3번|

<hr>
<a href="http://www.google.com">구글 방문</a>

![구글방문](http://www.google.com)
