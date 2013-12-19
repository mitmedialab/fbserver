CREATE INDEX account_uuid on accounts(uuid);
CREATE INDEX agj_gender ON account_gender_judgments(gender(10));
CREATE INDEX user_fbr ON followbias_records(user_id);
CREATE INDEX agj_user_id on account_gender_judgments(user_id);
CREATE INDEX account_image_update on accounts(profile_image_updated_at);

