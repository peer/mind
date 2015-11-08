class share.BaseDocument extends Document
  @Meta
    abstract: true

  @sanitize = share.sanitize

  @sanitizeForDisplay = share.sanitizeForDisplay
