서버는 임시로 ngrok 사용합니다. 매번 url주소가 바뀝니다.

서버주소 <br>
http://ec2-15-165-108-236.ap-northeast-2.compute.amazonaws.com:8001/"urls..."

---
## 프론트

## 백엔드
pycharm<br>
python: 3.12.2<br>
인터프리터 설정:
  맨날 다운받으면 인터프리터 없다고 짜증날 때.
  - 자신이 만든 가상환경폴더를 프로젝트 밖에 따로 빼낸다. 이러면 프로젝트를 삭제하고 다시 클론해도 쓸수있다.<br>
  
서버실행법:<br>
  방법1)프레임워크의 터미널로 가서 수작업으로 python manage.py runserver를 친다.<br>
  방법2)가상서버 실행환경을 등록할 때 manage.py를 스크립트파일로 정하고 파라미터를 runserver로 지정한다.



## AI

---
### 커밋RULE(꼭은아님!)
- feat 		: 새로운 기능 추가(기능추가 및 업데이트 관련)
- fix 		: 버그 수정
- docs 		: 문서 수정
- style 	: 코드 formatting, 세미콜론(;) 누락, 코드 변경이 없는 경우
- refactor 	: 코드 리팩토링
- test 		: 테스트 코드, 리팽토링 테스트 코드 추가
