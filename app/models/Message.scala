package models

import play.api.libs.json.Json
import reactivemongo.bson.BSONObjectID
import play.modules.reactivemongo.json.BSONFormats._

/**
 * A message class
 *
 * @param _id The BSON object id of the message
 * @param message The message
 * @param author The author of the message
 * @param likes The number of times the message has been liked
 */
case class Message(_id: BSONObjectID, message: String, author: String, likes: Int)

object Message {
  /**
   * Format for the message.
   *
   * Used both by JSON library and reactive mongo to serialise/deserialise a message.
   */
  implicit val messageFormat = Json.format[Message]
}