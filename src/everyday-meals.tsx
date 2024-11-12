'use client'

import React, { useState, createContext, useContext } from 'react'
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd'
import { Plus, GripVertical, Globe } from 'lucide-react'
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"

interface Meal {
  id: string
  name: string
  eaten: boolean
}

type Language = 'en' | 'sv' | 'fr' | 'de' | 'it' | 'nl'

const translations = {
  en: {
    title: 'Weekly Meal Tracker',
    addMeal: 'Add Meal',
    enterMeal: 'Enter a new meal',
    eaten: 'Eaten',
    uneaten: 'Uneaten',
    eatenMeals: 'Eaten Meals',
    selectLanguage: 'Select Language',
  },
  sv: {
    title: 'Veckans Måltidsspårare',
    addMeal: 'Lägg till Måltid',
    enterMeal: 'Ange en ny måltid',
    eaten: 'Äten',
    uneaten: 'Oäten',
    eatenMeals: 'Ätna Måltider',
    selectLanguage: 'Välj Språk',
  },
  fr: {
    title: 'Suivi des Repas Hebdomadaires',
    addMeal: 'Ajouter un Repas',
    enterMeal: 'Entrez un nouveau repas',
    eaten: 'Mangé',
    uneaten: 'Non Mangé',
    eatenMeals: 'Repas Mangés',
    selectLanguage: 'Choisir la Langue',
  },
  de: {
    title: 'Wöchentlicher Mahlzeiten-Tracker',
    addMeal: 'Mahlzeit Hinzufügen',
    enterMeal: 'Neue Mahlzeit eingeben',
    eaten: 'Gegessen',
    uneaten: 'Nicht Gegessen',
    eatenMeals: 'Gegessene Mahlzeiten',
    selectLanguage: 'Sprache Auswählen',
  },
  it: {
    title: 'Tracciatore Pasti Settimanale',
    addMeal: 'Aggiungi Pasto',
    enterMeal: 'Inserisci un nuovo pasto',
    eaten: 'Mangiato',
    uneaten: 'Non Mangiato',
    eatenMeals: 'Pasti Mangiati',
    selectLanguage: 'Seleziona Lingua',
  },
  nl: {
    title: 'Wekelijkse Maaltijdtracker',
    addMeal: 'Maaltijd Toevoegen',
    enterMeal: 'Voer een nieuwe maaltijd in',
    eaten: 'Gegeten',
    uneaten: 'Niet Gegeten',
    eatenMeals: 'Gegeten Maaltijden',
    selectLanguage: 'Taal Selecteren',
  },
}

const LanguageContext = createContext<{
  language: Language
  setLanguage: React.Dispatch<React.SetStateAction<Language>>
}>({
  language: 'en',
  setLanguage: () => {},
})

export default function MealTracker() {
  const [meals, setMeals] = useState<Meal[]>([])
  const [newMeal, setNewMeal] = useState('')
  const [language, setLanguage] = useState<Language>('en')

  const addMeal = () => {
    if (newMeal.trim() !== '') {
      setMeals([...meals, { id: Date.now().toString(), name: newMeal, eaten: false }])
      setNewMeal('')
    }
  }

  const toggleEaten = (id: string) => {
    setMeals(meals.map(meal => 
      meal.id === id ? { ...meal, eaten: !meal.eaten } : meal
    ))
  }

  const onDragEnd = (result: any) => {
    if (!result.destination) return

    const newMeals = Array.from(meals)
    const [reorderedItem] = newMeals.splice(result.source.index, 1)
    newMeals.splice(result.destination.index, 0, reorderedItem)

    setMeals(newMeals)
  }

  const uneatenMeals = meals.filter(meal => !meal.eaten)
  const eatenMeals = meals.filter(meal => meal.eaten)

  return (
    <LanguageContext.Provider value={{ language, setLanguage }}>
      <div className="max-w-md mx-auto p-4 relative">
        <div className="absolute top-4 right-4">
          <LanguageSwitcher />
        </div>
        <h1 className="text-2xl font-bold mb-4">{translations[language].title}</h1>
        <div className="flex mb-4">
          <Input
            type="text"
            value={newMeal}
            onChange={(e) => setNewMeal(e.target.value)}
            placeholder={translations[language].enterMeal}
            className="mr-2"
          />
          <Button onClick={addMeal}>
            <Plus className="w-4 h-4 mr-2" />
            {translations[language].addMeal}
          </Button>
        </div>
        <DragDropContext onDragEnd={onDragEnd}>
          <Droppable droppableId="meals">
            {(provided) => (
              <ul {...provided.droppableProps} ref={provided.innerRef} className="space-y-2">
                {uneatenMeals.map((meal, index) => (
                  <Draggable key={meal.id} draggableId={meal.id} index={index}>
                    {(provided) => (
                      <li
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        className="list-none"
                      >
                        <Card>
                          <CardContent className="p-4 flex items-center justify-between">
                            <div className="flex items-center">
                              <div {...provided.dragHandleProps} className="mr-2">
                                <GripVertical className="w-4 h-4 text-gray-400" />
                              </div>
                              <span>{meal.name}</span>
                            </div>
                            <Button
                              onClick={() => toggleEaten(meal.id)}
                              variant="default"
                              size="sm"
                            >
                              {translations[language].eaten}
                            </Button>
                          </CardContent>
                        </Card>
                      </li>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </ul>
            )}
          </Droppable>
        </DragDropContext>
        {eatenMeals.length > 0 && (
          <>
            <Separator className="my-4" />
            <h2 className="text-lg font-semibold mb-2">{translations[language].eatenMeals}</h2>
            <ul className="space-y-2">
              {eatenMeals.map((meal) => (
                <li key={meal.id} className="list-none">
                  <Card>
                    <CardContent className="p-4 flex items-center justify-between">
                      <span>{meal.name}</span>
                      <Button
                        onClick={() => toggleEaten(meal.id)}
                        variant="outline"
                        size="sm"
                      >
                        {translations[language].uneaten}
                      </Button>
                    </CardContent>
                  </Card>
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </LanguageContext.Provider>
  )
}

function LanguageSwitcher() {
  const { language, setLanguage } = useContext(LanguageContext)

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="icon">
          <Globe className="h-4 w-4" />
          <span className="sr-only">{translations[language].selectLanguage}</span>
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-48">
        <Select value={language} onValueChange={(value: Language) => setLanguage(value)}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder={translations[language].selectLanguage} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="en">English</SelectItem>
            <SelectItem value="sv">Svenska</SelectItem>
            <SelectItem value="fr">Français</SelectItem>
            <SelectItem value="de">Deutsch</SelectItem>
            <SelectItem value="it">Italiano</SelectItem>
            <SelectItem value="nl">Nederlands</SelectItem>
          </SelectContent>
        </Select>
      </PopoverContent>
    </Popover>
  )
}