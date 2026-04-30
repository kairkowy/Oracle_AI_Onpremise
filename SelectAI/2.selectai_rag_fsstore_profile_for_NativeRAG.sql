-----------------------------------
-- SELECTAI RAG 프로파일 :  SAI_RAG_FSSTORE_PROFILE 
-- 파일시스템의 지정된 디렉토리에 있는 문서 파일을 자동으로 벡터 인덱싱을 합니다.
-- 파일시스템 위치 : /home/poc3/poc_data
----------------------------------
BEGIN
  BEGIN
    DBMS_CLOUD_AI.DROP_PROFILE('SAI_RAG_FSSTORE_PROFILE', force => TRUE);
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'SAI_RAG_FSSTORE_PROFILE',
    attributes   => '{
      "provider_endpoint": "http://service-ollama",
      "model": "exaone3.5",
      "conversation": false,
      "temperature": 0.0,
      "max_tokens": 2048,
      "vector_index_name":"SAI_RAG_IDX",
      "embedding_model": "database:MULTILINGUAL_E5_SMALL"
    }',
    status => 'enabled'
  );
END;
/

EXECUTE DBMS_CLOUD_AI.SET_PROFILE('SAI_RAG_FSSTORE_PROFILE');

-----------------------------------------
-- Vector/RAG용 벡터 인덱싱 using SAI_RAG_FSSTORE_PROFILE 
----------------------------------------
BEGIN
  -- 기존 인덱스 있으면 삭제
  BEGIN
    DBMS_CLOUD_AI.DROP_VECTOR_INDEX(
      index_name   => 'SAI_RAG_IDX',
      include_data => TRUE,
      force        => TRUE
    );
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  -- 벡터 인덱스 생성
  DBMS_CLOUD_AI.CREATE_VECTOR_INDEX(
    index_name => 'SAI_RAG_IDX',
    attributes        => '{
          "vector_db_provider": "oracle",
          "location": "DOC_DIR:*.*",
          "profile_name": "SAI_RAG_FSSTORE_PROFILE",
          "vector_dimension": 384,
          "vector_distance_metric": "cosine",
          "similarity_threshold": 0.75,
          "match_limit": 3
        }'
  );
END;
/

EXECUTE DBMS_CLOUD_AI.SET_PROFILE('SAI_RAG_FSSTORE_PROFILE');

--          "chunk_size":200,
--          "chunk_overlap":20

공무사 요양비 승인 절차


입원 시 준비해야할 서류 