CREATE INDEX account_uuid on accounts(uuid);
CREATE INDEX agj_gender ON account_gender_judgments(gender(10));
CREATE INDEX user_fbr ON followbias_records(user_id);
